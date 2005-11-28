#!/usr/bin/perl

package Common;

use warnings;
use strict;
use CGI;
use DBI;

############################
## Configuration
my %conf = (
	who	=>	'My Company',
	dbi	=>	'dbi',
	dbd	=>	'mysql',
	dbhost	=>	'localhost',
	dbport	=>	3306,
	db	=>	'sharkmate',
	dbuser	=>	'sharkmate',
	dbpass	=>	'sharkmatepw',
);
############################

sub new {
	my $class = shift;
	my $self = { };
	bless $self, $class;
	$self->{query} = new CGI or return;
	$self->{dbh} = DBI->connect( "$conf{dbi}:$conf{dbd}:$conf{db};host=$conf{dbhost};port=$conf{dbport}", $conf{dbuser}, $conf{dbpass} ) or return;
	foreach my $key ( $self->{query}->param ) {
		$self->{vars}->{$key} = $self->{query}->param( $key );
	}
	$self->{heap} = { };
	return $self;
}

sub commify {
	local $_  = shift;
	1 while s/^([-+]?\d+)(\d{3})/$1,$2/;
	return $_;                          
}

1;
