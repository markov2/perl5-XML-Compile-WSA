# This code is part of distribution XML-Compile-WSA.  Meta-POD processed
# with OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package XML::Compile::WSA::Util;
use base 'Exporter';

use warnings;
use strict;

my @wsa09  = qw/WSA09 WSA09FAULT WSA09ROLE_ANON/;
my @wsa10  = qw/WSA10 WSA10FAULT WSA10ADDR_ANON WSA10ADDR_NONE
                WSA10REL_REPLY WSA10REL_UNSPEC WSA10MODULE WSA10SOAP_FAULT/;
my @wsdl11 = qw/WSDL11WSAW/;
my @wsdl12 = ();  # don't know (yet)
my @soap11 = ();
my @soap12 = qw/SOAP12FEAT_DEST SOAP12FEAT_SE SOAP12FEAT_RE SOAP12FEAT_FE
                SOAP12FEAT_ACT SOAP12FEAT_ID SOAP12FEAT_REL SOAP12FEAT_REF/;

our @EXPORT_OK = (@wsa09, @wsa10, @wsdl11, @wsdl12, @soap11, @soap12);
our %EXPORT_TAGS =
  ( wsa09  => \@wsa09
  , wsa10  => \@wsa10
  , wsdl11 => \@wsdl11
  , wsdl12 => \@wsdl12
  , soap11 => \@soap11
  , soap12 => \@soap12
  );

=chapter NAME
XML::Compile::WSA::Util - constants for XML::Compile::WSA

=chapter SYNOPSIS
 use XML::Compile::WSA::Util qw/:wsa10/;

=chapter DESCRIPTION
This module collects constants used by the Web Service Addressing
standard.

=chapter FUNCTIONS

=section Constants

Export TAG C<:wsa09> exports constants C<WSA09> (Web Service Addressing),
C<WSA09_ROLE_ANON>, and C<WSA09_FAULT>.
=cut

use constant
  { WSA09           => 'http://schemas.xmlsoap.org/ws/2004/08/addressing'
  , WSA10           => 'http://www.w3.org/2005/08/addressing'
  };

use constant
  { WSA09FAULT      => WSA09.'/fault'
  , WSA09ROLE_ANON  => WSA09.'/role/anonymous'
  };

=pod

Export TAG C<:wsa10> delivers constants C<WSA10>,
C<WSA10ADDR_ANON>, C<WSA10ADDR_NONE>,
C<WSA10REL_REPLY>, C<WSA10REL_UNSPEC>,
C<WSA10FAULT>, C<WSA10SOAP_FAULT>,
and C<WSA10MODULE>.
The latter is an abstract name for the software component.

=cut

use constant
  { WSA10FAULT      => WSA10.'/fault'
  , WSA10SOAP_FAULT => WSA10.'/soap/fault'
  , WSA10ADDR_ANON  => WSA10.'/anonymous'
  , WSA10ADDR_NONE  => WSA10.'/none'
  , WSA10REL_REPLY  => WSA10.'/reply'
  , WSA10REL_UNSPEC => WSA10.'/unspecified'
  , WSA10MODULE     => WSA10.'/module'
  };

=pod
Export TAG C<:wsdl11> provides constants C<WSDL11WSAW>.
=cut

use constant
  { WSDL11WSAW      => 'http://www.w3.org/2006/05/addressing/wsdl'
  };

=pod
Export TAG C<:wsdl20> provides no constants (yet)

Export TAG C<:soap11> defines nothing (yet)

Export TAG C<:soap12> provides constants C<SOAP12FEAT_DEST> (Destination), 
C<_SE> (SourceEndpoint>, C<_RE> (ReplyEndpoint), <C_FE> (FaultEndpoint),
C<_ACT> (Action), C<_ID> (MessageID), C<_REL> (Relationship), and
C<_REF> (ReferenceParameters).
=cut

use constant
  { SOAP12FEATURE   => 'http://www.w3.org/2005/08/addressing/feature'
  };

use constant
  { SOAP12FEAT_DEST => SOAP12FEATURE.'/Destination'
  , SOAP12FEAT_SE   => SOAP12FEATURE.'/SourceEndpoint'
  , SOAP12FEAT_RE   => SOAP12FEATURE.'/ReplyEndpoint'
  , SOAP12FEAT_FE   => SOAP12FEATURE.'/FaultEndpoint'
  , SOAP12FEAT_ACT  => SOAP12FEATURE.'/Action'
  , SOAP12FEAT_ID   => SOAP12FEATURE.'/MessageID'
  , SOAP12FEAT_REL  => SOAP12FEATURE.'/Relationship'
  , SOAP12FEAT_REF  => SOAP12FEATURE.'/ReferenceParameters'
  };

1;

