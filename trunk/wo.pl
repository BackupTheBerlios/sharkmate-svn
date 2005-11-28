#!/usr/bin/perl

use warnings;
use strict;
use WorkOrders;
use WWW::CMS;

my $wo = WorkOrders->new();
my $q = $wo->{common}->{query};
my $vars = $wo->{common}->{vars};
my $me = $q->url();
my $cms = WWW::CMS->new({	TemplateBase	=>	'/home/x86/webmodules',
				Module		=>	'contacts.xml'	});
print $q->header;
$cms->{PageName} = 'Work Orders';

if ( !$vars->{act} || !$wo->{dispatch}{ $vars->{act} } ) {
	# Show all open WO
	push ( @{ $cms->{content} }, show_open_wo( $q, $vars, $wo ) );
}
else {
	# act passed in and has handler in dispatch table
	push ( @{ $cms->{content} }, $wo->{dispatch}->{ $vars->{act} }->( $q, $vars, $contact, $wo ) );
} 

print $cms->publicize( $q );

exit;
