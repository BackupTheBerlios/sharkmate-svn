#!/usr/bin/perl

package Accounts;

use warnings;
use strict;
use Common;

sub new {
	my $class = shift;
	my $self = { };
	bless $self, $class;
	return $self;
}

1;
