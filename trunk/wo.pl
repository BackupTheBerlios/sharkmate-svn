#!/usr/bin/perl

use warnings;
use strict;
use WorkOrders;
use WWW::CMS;
use CGI;

my $q = CGI->new();
my $wo = WorkOrders->new();
my $vars = $wo->{common}->{vars};
my $cms = WWW::CMS->new({	TemplateBase	=>	'/home/x86/webmodules',
				Module		=>	'contacts.xml'	});

print STDERR "Have query in wo.pl at line: " . __LINE__ . "\n" if $q;

print $q->header;
$cms->{PageName} = 'Work Orders';

if ( !$vars->{act} || !$wo->{dispatch}{ $vars->{act} } ) {
	# Show all open WO
	print STDERR "DO NOT HAVE QUERY IN wo.pl AT LINE: " . __LINE__ . "\n" unless $q;
	push ( @{ $cms->{content} }, $wo->show_open_wo( $q, $vars ) );
}
else {
	# act passed in and has handler in dispatch table
	print STDERR "DO NOT HAVE QUERY IN wo.pl AT LINE: " . __LINE__ . "\n" unless $q;
	push ( @{ $cms->{content} }, $wo->{dispatch}->{ $vars->{act} }->( $q, $vars ) );
} 

print $cms->publicize( $q );

exit;
