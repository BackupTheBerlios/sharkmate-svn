#!/usr/bin/perl

package WorkOrders;

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

sub get_all_companies {
	my $self = shift;
	my $sth = $self->{common}->{dbh}->prepare( 'SELECT seq,name FROM www_companies' ) or do {
		print STDERR "Failed to prepare SQL query: " . $self->{common}->{dbh}->errstr;
		return;
	};
	$sth->execute() or do {
		print STDERR "Faile to execute SQL query: " . $self->{common}->{dbh}->errstr;
		$sth->finish;
		return;
	};
	my %results;
	while ( my $row = $sth->fetchrow_hashref ) {
		$results{$row->{seq}} = $row->{name};
	}
	$sth->finish;
	return \%results;
}

sub get_all_employees {
	my $self = shift;
	my $sth = $self->{common}->{dbh}->prepare( 'SELECT seq,CONCAT(lname,", ",fname) AS name FROM www_employees' ) or do {
		print STDERR "Failed to prepare SQL query: " . $self->{common}->{dbh}->errstr;
		return;
	};
	$sth->execute() or do {
		print STDERR "Faile to execute SQL query: " . $self->{common}->{dbh}->errstr;
		$sth->finish;
		return;
	};
	my %results;
	while ( my $row = $sth->fetchrow_hashref ) {
		$results{$row->{seq}} = $row->{name};
	}
	$sth->finish;
	return \%results;
}

sub get_all_phases {
	my $self = shift;
	my $sth = $self->{common}->{dbh}->prepare( 'SELECT seq,code FROM www_phases' ) or do {
		print STDERR "Failed to prepare SQL query: " . $self->{common}->{dbh}->errstr;
		return;
	};
	$sth->execute() or do {
		print STDERR "Faile to execute SQL query: " . $self->{common}->{dbh}->errstr;
		$sth->finish;
		return;
	};
	my %results;
	while ( my $row = $sth->fetchrow_hashref ) {
		$results{$row->{seq}} = $row->{code};
	}
	$sth->finish;
	return \%results;
}

sub lookup_wo_by_seq {
	my ( $self, $seq ) = @_;
	my $sth = $self->{common}->{dbh}->prepare( 'SELECT ref,company,status,invoice FROM wo_ticket WHERE seq = ? LIMIT 1' ) or do {
		print STDERR "Failed to prepare SQL query: " . $self->{common}->{dbh}->errstr;
		return;
	};
	$sth->execute( $seq ) or do {
		print STDERR "Failed to execute SQL query: " . $self->{common}->{dbh}->errstr;
		$sth->finish;
		return;
	}; 
	my $row = $sth->fetchrow_hashref;
	return $row unless !$row;
	return;
}

sub get_all_open_wo {
	my $self = shift;
	my $sth = $self->{common}->{dbh}->prepare( 'SELECT seq,ref,ts,company,descr FROM wo_ticket WHERE status = 0 ORDER BY ref ASC' ) or do {
		print STDERR "Failed to prepare SQL query: " . $self->{common}->{dbh}->errstr;
		return;
	};
	$sth->execute() or do {
		print STDERR "Failed to execute SQL query: " . $self->{common}->{dbh}->errstr;
		$sth->finish;
		return;
	};
	my @results;
	while (my $row = $sth->fetchrow_hashref) {
		push ( @results, $row );
	}
	$sth->finish;
	return \@results;
}

sub get_li_by_wo_seq {
	my ( $self, $seq ) = @_;
	my $sth = $self->{common}->{dbh}->prepare( 'SELECT wo_line_item.seq,wo_line_item.ts,CONCAT(www_employees.lname,", ",www_employees.fname) AS employee,wo_line_item.descr,wo_line_item.hours,phase AS phaseseq,www_phases.code AS phase,SUM(wo_line_item.hours * www_phases.cost) AS cost FROM wo_line_item LEFT JOIN www_employees ON wo_line_item.employee = www_employees.seq LEFT JOIN www_phases ON www_phases.seq = wo_line_item.phase WHERE wo = ? GROUP BY wo_line_item.seq' ) or do {
		print STDERR "Failed to prepare SQL query: " . $self->{common}->{dbh}->errstr;
		return;
	};
	$sth->execute( $seq ) or do {
		print STDERR "Failed to execute SQL query " . $self->{common}->{dbh}->errstr;
		$sth->finish;
		return;
	};
	my @results;
	while (my $row = $sth->fetchrow_hashref) {
		push ( @results, $row );
	}
	$sth->finish;
	return \@results;
}

sub add_wo {
	my ( $self, $entity ) = @_;
	my $sth = $self->{common}->{dbh}->prepare( 'INSERT INTO wo_ticket VALUES( NULL,?,?,NOW()+0,?,0,0 )' ) or do {
		print STDERR "Failed to prepare SQL query: " . $self->{common}->{dbh}->errstr;
		return;
	};
	$sth->execute( $entity->{company}, $entity->{won}, 'Added from web interface' ) or do {
		print STDERR "Failed to execute SQL query: " . $self->{common}->{dbh}->errstr;
		$sth->finish;
		return;
	};
	$sth->finish;
	$sth = $self->{common}->{dbh}->prepare( 'SELECT seq FROM wo_ticket WHERE ref = ? LIMIT 1' ) or do {
		print STDERR "Failed to prepare SQL query: " . $self->{common}->{dbh}->errstr;
		return;
	};
	$sth->execute( $entity->{won} ) or do {
		print STDERR "Failed to execute SQL query: " . $self->{common}->{dbh}->errstr;
		$sth->finish;
		return;
	};
	my $row = $sth->fetchrow_hashref;
	$sth->finish;

	return $row->{seq};
}

sub add_li_to_wo {
	my ( $self, $entity ) = @_;
	my $sth = $self->{common}->{dbh}->prepare( 'INSERT INTO wo_line_item VALUES( NULL,?,NOW()+0,?,?,?,? )' ) or do {
		print STDERR "Failed to prepare SQL query: " . $self->{common}->{dbh}->errstr;
		return;
	};
	my $rc = $sth->execute( $entity->{won}, $entity->{employee}, $entity->{descr}, $entity->{hours}, $entity->{phase} ) or do {
		print STDERR "Failed to execute SQL query: " . $self->{common}->{dbh}->errstr;
		$sth->finish;
		return;
	};
	$sth->finish;
	return $rc;
}

sub change_li {
	my ( $self, $entity ) = @_;
	my $sth = $self->{common}->{dbh}->prepare( 'UPDATE wo_line_item SET employee = ?, descr = ?, hours = ?, phase = ? WHERE seq = ? LIMIT 1' ) or do {
		print STDERR "Failed to prepare SQL query: " . $self->{common}->{dbh}->errstr;
		return;
	};
	my $rc = $sth->execute( $entity->{employee}, $entity->{descr}, $entity->{hours}, $entity->{phase}, $entity->{liseq} ) or do {
		print STDERR "Failed to execute SQL query: " . $self->{common}->{dbh}->errstr;
		$sth->finish;
		return;
	};
	$sth->finish;
	return $rc;
}

sub get_all_open_inv {
	my ( $self ) = @_;
	my $sth = $self->{common}->{dbh}->prepare( 'SELECT seq,descr FROM invoices WHERE status = 0' ) or do {
		print STDERR "Failed to prepare SQL query: " . $self->{common}->{dbh}->errstr;
		return;
	};
	$sth->execute or do {
		print STDERR "Failed to execute SQL query " . $self->{common}->{dbh}->errstr;
		$sth->finish;
		return;
	};
	my %results;
	while (my $row = $sth->fetchrow_hashref) {
		$results{$row->{seq}} = $row->{descr};
	}
	$results{0} = '--------';
	$sth->finish;
	return \%results;
}

1;
