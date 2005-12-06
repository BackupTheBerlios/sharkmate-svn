#!/usr/bin/perl

package Sharkmate::Accounts;

use warnings;
use strict;
use Sharkmate::Common;

sub new {
	my $class = shift;
	my $self = { };
	bless $self, $class;
	return $self;
}

1;
