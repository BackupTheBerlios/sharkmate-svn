#!/usr/bin/perl

use warnings;
use strict;
use Accounts;
use WWW::CMS;
use POSIX qw( strftime );

my $acct = Accounts->new();
my $q = $acct->{common}->{query};
my $vars = $acct->{common}->{vars};
my $me = $q->url();
my $cms = WWW::CMS->new({	TemplateBase	=>	'/home/x86/webmodules',
				Module		=>	'contacts.xml'	});

print $q->header;
$cms->{PageName} = 'Accounting';

if ( $vars->{act} ) {
	if ( $vars->{act} =~ /^00000000$/ ) {
		# Show all invoices
	}
	elsif ( $vars->{act} =~ /^00010000$/ ) {
		# Find invoice
	}
	elsif ( $vars->{act} =~ /^00100000$/ ) {
		# Create invoice
	}
	else {
		# Invalid action specified
		push ( @{ $cms->{content} }, 'Invalid action specified' );
	}
}
else {
	# WTFBBQ?! No action specified
	push ( @{ $cms->{content} }, 'No action specified' );
}

print $cms->publicize( $q );

return 1;
exit;
