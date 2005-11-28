#!/usr/bin/perl

use warnings;
use strict;
use WorkOrders;
use WWW::CMS;
use CGI;

my $q = CGI->new();
my $wo = WorkOrders->new();
my $vars = $wo->{common}->{vars};
my $cms = WWW::CMS->new({
	TemplateBase	=>	$wo->{common}->{conf}->{TemplateBase},
	Module		=>	$wo->{common}->{conf}->{Module}
});

print $q->header;
$cms->{PageName} = 'Work Orders';

if ( !$vars->{act} || !$wo->{dispatch}{ $vars->{act} } ) {
	# Show all open WO
	push ( @{ $cms->{content} }, $wo->show_open_wo( $q, $vars ) );
}
else {
	# act passed in and has handler in dispatch table
	push ( @{ $cms->{content} }, $wo->{dispatch}->{ $vars->{act} }->( $q, $vars ) );
} 

print $cms->publicize( $q );

exit;
