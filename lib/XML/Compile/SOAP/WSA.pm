use warnings;
use strict;

package XML::Compile::SOAP::WSA;
use base 'XML::Compile::SOAP::Extension';

use Log::Report 'xml-compile-soap-wsa';

use XML::Compile::SOAP::WSA::Util qw/WSA10MODULE WSA09 WSA10 WSDL11WSAW/;

use File::Spec              ();
use File::Basename          qw/dirname/;

my @common_hdr_elems = qw/To From Action ReplyTo FaultTo MessageID
  RelatesTo RetryAfter/;
my @wsa09_hdr_elems  = (@common_hdr_elems, qw/ReplyAfter/);
my @wsa10_hdr_elems  = (@common_hdr_elems, qw/ReferenceParameters/);

my %versions =
  ( '0.9' => { xsd => '20070619-wsa09.xsd', wsa => WSA09
             , hdr => \@wsa09_hdr_elems }
  , '1.0' => { xsd => '20080723-wsa10.xsd', wsa => WSA10
             , hdr => \@wsa10_hdr_elems }
  );

=chapter NAME
XML::Compile::SOAP::WSA - SOAP Web Service Addressing

=chapter SYNOPSIS
 # load the module
 use XML::Compile::SOAP::WSA;
 my $wsa  = XML::Compile::SOAP::WSA->new(version => '1.0');

 # you may need some constants (rarely)
 use XML::Compile::SOAP::WSA::Util ':wsa10';

 # use WSA via WSDL
 my $wsdl = XML::Compile::WSDL11->new(...);
 $wsdl->extension($wsa);
 my $call = $wsdl->compileClient('some_operation');

 # wsa header fields start with wsa_
 my ($data, $trace) = $call->(wsa_MessageID => 'xyz', %data);

=chapter DESCRIPTION
The Web Service Addressing protocol is used to select certain
service and port on a SOAP server, just like the "Host" header
in C<HTTP>.

The basic SOAP design uses the URI and the C<soapAction> header of HTTP
(in case it uses HTTP, by far the most often used transport mechanism)
However, when the server is hidden behind firewalls and proxies, these
fields are rewritten or replaced.  This means that the definitions by
the WSDL for the client can differ from the configuration of the server.
This is where WSA comes into play.

When WSA is enabled, header fields are added. Automatically, the
obligatory C<wsa_To> and C<wsa_Action> fields will be added to
each request, although you may change their values with call
parameters.

B<Warning:> this being a very recent module, thing may not work. There
is no real-life experience with the code, as yet. Please contact the
author when you are succesful or discovered problems.

=chapter METHODS

=section Constructors

=c_method new OPTIONS

=requires version '0.9'|'1.0'|MODULE
Explicitly state which version WSA needs to be produced.
You may use a version number (where C<0.9> is used to represent
the "submission" specification). You may also use the MODULE
name, which is a namespace constant, provided via C<::Util>.
The only option is currently C<WSL10MODULE>.

=cut

sub init($)
{   my ($self, $args) = @_;

    $self->SUPER::init($args);
    my $version = $args->{version}
        or error __x"explicit wsa_version required";
    trace "initializing wsa $version";

    $version = '1.0' if $version eq WSA10MODULE;
    $versions{$version}
        or error __x"unknown wsa version {v}, pick from {vs}"
             , v => $version, vs => [keys %versions];
    $self->{version} = $version;
    $self;
}

#-----------

=section Attributes

=method version
Returns the version number.
=method wsaNS
Returns the namespace used for this WSA version.
=cut

sub version() {shift->{version}}
sub wsaNS()   {$versions{shift->{version}}{wsa}}

#-----------

sub _load_ns($$)
{   my ($self, $schema, $fn) = @_;
    my $xsd = File::Spec->catfile(dirname(__FILE__), 'WSA', 'xsd', $fn);
    $schema->importDefinitions($xsd);
}

sub wsdl11Init($@)
{   my ($self, $wsdl, $args) = @_;
    my $def = $versions{$self->{version}};

    my $ns = $self->wsaNS;
    $wsdl->prefixes(wsa => $ns, wsaw => WSDL11WSAW);

    trace "loading wsa $self->{version}";
    $self->_load_ns($wsdl, $def->{xsd});
    $self->_load_ns($wsdl, '20060512-wsaw.xsd');

    # For unknown reason, the FaultDetail header is described everywhere,
    # except in the schema.
    $wsdl->importDefinitions( <<_FAULTDETAIL );
<schema xmlns="http://www.w3.org/2001/XMLSchema"
     xmlns:tns="$ns" targetNamespace="$ns"
     elementFormDefault="qualified"
     attributeFormDefault="unqualified">
  <element name="FaultDetail">
    <complexType>
      <sequence>
        <any minOccurs="0" maxOccurs="unbounded" />
      </sequence>
    </complexType>
  </element>
</schema>
_FAULTDETAIL

   $self;
}

sub soap11OperationInit($@)
{   my ($self, $op, %args) = @_;
    my $ns = $self->wsaNS;

    trace "adding wsa header logic";
    my $def = $versions{$self->{version}};
    foreach my $hdr ( @{$def->{hdr}} )
    {   $op->addHeader(INPUT  => "wsa_$hdr" => "{$ns}$hdr");
        $op->addHeader(OUTPUT => "wsa_$hdr" => "{$ns}$hdr");
    }

    # soap11 specific
    $op->addHeader(OUTPUT => wsa_FaultDetail => "{$ns}FaultDetail");
}

sub soap11ClientWrapper($$@)
{   my ($self, $op, $call, %args) = @_;
    my $to     = $args{To}     || ($op->endPoints)[0];
    my $action = $args{Action} || $op->soapAction;

    trace "added wsa in call $to for $action";
    sub
    {   $call->(wsa_To => $to, wsa_Action => $action, @_);
    };
}

=section SEE ALSO
=over 4
=item Web Services Addressing 1.0 - Core
F<http://www.w3.org/TR/ws-addr-core>, 9 May 2006

=item Web Services Addressing 1.0 - SOAP Binding
F<http://www.w3.org/TR/ws-addr-soap>, 9 May 2006

=item Web Services Addressing 1.0 - WSDL Binding
F<http://www.w3.org/TR/ws-addr-wsdl>, 29 May 2006
=back
=cut

1;
