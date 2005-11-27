#!/usr/bin/perl

package Accounts;

use warnings;
use strict;
use Common;

sub new {
	my $class = shift;
	my $self = { };
	bless $self, $class;
	$self->{common} = new Common or do {
		print STDERR "Failed to create Common.pm reference";
		return;
	};
	return $self;
}

1;
