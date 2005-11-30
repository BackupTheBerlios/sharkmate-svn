#!/usr/bin/perl

use warnings;
use strict;
use Common;
use WWW::CMS;
use Auth::Sticky;

## Currently moving everything out of contacts.pl, wo.pl, accounts.pl into
## their respective section's module to clean up quite a bit.
##	contacts.pl => done

## Authentication should probably happen here too via Auth::Sticky



my $self = { };
bless $self;

$self->{_common} = Common->new();
$self->{_cms} = WWW::CMS->new({
	TemplateBase	=>	$self->{_common}->{conf}->{TemplateBase},
	Module		=>	$self->{_common}->{conf}->{Module}
});

# Autoload these function handlers
my @autoload = (
	'Contacts',
	'Accounts',
	'WorkOrders',
);

foreach ( @autoload ) {
	my $x=$_;
	s#::#/#g;
	s/$/.pm/;
	require $_; 
	$self->{$x} = $x->new();
}
