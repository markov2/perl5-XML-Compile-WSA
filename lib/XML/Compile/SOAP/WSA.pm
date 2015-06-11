use warnings;
use strict;

package XML::Compile::SOAP::WSA;
use base 'XML::Compile::SOAP::Extension';

use Log::Report 'xml-compile-soap-wsa';

use XML::Compile::WSA::Util  qw/WSA10MODULE WSA09 WSA10 WSDL11WSAW/;
use XML::Compile::SOAP::Util qw/WSDL11/;
use XML::Compile::Util       qw/pack_type/;

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

my $xsddir = File::Spec->catdir((dirname dirname __FILE__), 'WSA', 'xsd');

=chapter NAME
XML::Compile::SOAP::WSA - SOAP Web Service Addressing

=chapter SYNOPSIS

 # use WSA via WSDL, wsa header fields start with wsa_
 use XML::Compile::WSDL11;     # first
 use XML::Compile::SOAP::WSA;  # hooks into wsdl

 my $wsa  = XML::Compile::SOAP::WSA->new(version => '1.0');
 my $wsdl = XML::Compile::WSDL11->new(...);
 my $call = $wsdl->compileClient('some_operation');
 my ($data, $trace) = $call->(wsa_MessageID => 'xyz', %data);

 print $wsdl->operation('myop')->wsaAction;

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
obligatory C<wsa_To> and C<wsa_Action> fields will be added to each
request, although you may change their values with call parameters.
This works both for soap clients (created with M<XML::Compile::SOAP>)
as for the soap server (created with M<XML::Compile::SOAP::Daemon>):
simply require the WSA module to get the hooks installed.

Supported fields:

  Action
  FaultTo
  From
  MessageID
  RelatesTo
  ReplyTo
  RetryAfter
  To

=chapter METHODS

=section Constructors

=c_method new %options

=requires version '0.9'|'1.0'|MODULE
Explicitly state which version WSA needs to be produced.
You may use a version number (where C<0.9> is used to represent
the "submission" specification). You may also use the MODULE
name, which is a namespace constant, provided via C<::Util>.
The only option is currently C<WSA10MODULE>.

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

# This is not uglier than the WSA specification does: if you do not
# specify these attributes cleanly in the WSDL specs, then everyone
# needs hacks.
# Documented in XML::Compile::SOAP::Operation

sub XML::Compile::SOAP::Operation::wsaAction($)
{  my ($self, $dir) = @_;
   $dir eq 'INPUT' ? $self->{wsa}{action_input} : $self->{wsa}{action_output};
}

#-----------

sub _load_ns($$)
{   my ($self, $schema, $fn) = @_;
    $schema->importDefinitions(File::Spec->catfile($xsddir, $fn));
}

sub wsdl11Init($$)
{   my ($self, $wsdl, $args) = @_;
    my $def = $versions{$self->{version}};

    my $ns = $self->wsaNS;
    $wsdl->addPrefixes(wsa => $ns, wsaw => WSDL11WSAW);
    $wsdl->addKeyRewrite('PREFIXED(wsa,wsaw)');

    $wsdl->addCompileOptions('READERS'
      , anyElement   => 'TAKE_ALL'
      , anyAttribute => 'TAKE_ALL'
      );

    trace "loading wsa $self->{version}";
    $self->_load_ns($wsdl, $def->{xsd});
    $self->_load_ns($wsdl, '20060512-wsaw.xsd');

    my $wsa_action_ns = $self->version eq '0.9' ? $ns : WSDL11WSAW;
    $wsdl->addHook
      ( action => 'READER'
      , type   => pack_type(WSDL11, 'tParam')
      , after  => sub
          { my ($xml, $data, $path) = @_;
            $data->{wsa_action} = $xml->getAttributeNS($wsa_action_ns,'Action');
            $data;
          }
      );

    # [0.94] Many headers may contain attributes (which are usually not auto-
    # detected anyway), which will cause the field to be a HASH.  Older
    # versions of this module would always simply return the content, not a
    # HASH.  Let's not break those.
    $wsdl->addHook
      ( action => 'READER'
      , type   => 'wsa:AttributedURIType'
      , after  => sub
          { my ($xml, $data, $path) = @_;
            $data = $data->{_}
                if ref $data eq 'HASH' && keys %$data==1 && $data->{_};
            $data;
          }
      );

    # For unknown reason, the FaultDetail header is described everywhere
    # in the docs, but missing from the schema.
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

sub soap11OperationInit($$)
{   my ($self, $op, $args) = @_;
    my $ns = $self->wsaNS;

    $op->{wsa}{action_input}  = $args->{input_def}{body}{wsa_action};
    $op->{wsa}{action_output} = $args->{output_def}{body}{wsa_action};

    trace "adding wsa header logic";
    my $def = $versions{$self->{version}};
    foreach my $hdr ( @{$def->{hdr}} )
    {   $op->addHeader(INPUT  => "wsa_$hdr" => "{$ns}$hdr");
        $op->addHeader(OUTPUT => "wsa_$hdr" => "{$ns}$hdr");
    }

    # soap11 specific
    $op->addHeader(OUTPUT => wsa_FaultDetail => "{$ns}FaultDetail");
}
*soap12OperationInit = \&soap11OperationInit;

sub soap11ClientWrapper($$$)
{   my ($self, $op, $call, $args) = @_;
    my $to     = ($op->endPoints)[0];
    my $action = $op->wsaAction('INPUT') || $op->soapAction;
#   my $outact = $op->wsaAction('OUTPUT');

    trace "added wsa in call $to".($action ? " for $action" : '');
    sub
    {   my $data = @_==1 ? shift : {@_};
        $data->{wsa_To}     ||= $to;
        $data->{wsa_Action} ||= $action;
        $call->($data);
        # should we check that the wsa_Action in the reply is correct?
    };
}
*soap12ClientWrapper = \&soap11ClientWrapper;

sub soap11HandlerWrapper($$$)
{   my ($self, $op, $cb, $args) = @_;
    my $outact = $op->wsaAction('OUTPUT');
    defined $outact
        or return $cb;

    sub
    {   my $data = $cb->(@_);
        $data->{wsa_Action} = $outact;
        $data;
    };
}
*soap12HandlerWrapper = \&soap11HandlerWrapper;

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
