#!/usr/bin/perl

package Contacts;

use warnings;
use strict;
use Common;

sub new {
	my $class = shift;
	my $self = { };
	bless $self, $class;
	$self->{common} = new Common;
	return $self;
}

sub insert_contact {
	my $self = shift;
	my $entity = shift;

	$self->{errstr} = undef;

	if ( !$entity ) {
		$self->{errstr} = "No entity given to insert!";
		return;
	}

	# Check for a duplicate contact
	if ( $self->lookup_contact( lc($entity->{email}) ) ) {
		$self->{errstr} = "Refusing to duplicate contact: $entity->{email}";
		return;
	}

	# If we get this far, we should be good for inserting
	my $sth = $self->{common}->{dbh}->prepare( "INSERT INTO www_contacts (prefix,fname,lname,email,company,url,phone,ext,cell,fax,prefer,address,suite,zipcode) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)" ) or do {
		# This should never happen if the above worked ok
		$self->{errstr} = "Failed to prepare SQL query: " . $self->{common}->{dbh}->errstr;
		return;
	};
	$sth->execute( $entity->{prefix}, $entity->{fname}, $entity->{lname}, lc( $entity->{email} ), $entity->{company}, $entity->{url}, $entity->{phone}, $entity->{ext}, $entity->{cell}, $entity->{fax}, $entity->{prefer}, $entity->{address}, $entity->{suite}, $entity->{zip} ) or do {
		# This may happen, if fed bad data or such
		$self->{errstr} = "Failed to execute SQL query: " . $self->{common}->{dbh}->errstr;
		$sth->finish;
		return;
	};
	$sth->finish;

	# Yay!
	return 1;
}

sub insert_company {
	my $self = shift;
	my $entity = shift;

	$self->{errstr} = undef;

	if ( !$entity ) {
		$self->{errstr} = "No entity given to insert!";
		return;
	}

	# Check for a duplicate company
	if ( $self->lookup_company( lc($entity->{name}) ) ) {
		$self->{errstr} = "Refusing to duplicate company: $entity->{name}";
		return;
	}

	# If we get this far, we should be good for inserting
	my $sth = $self->{common}->{dbh}->prepare( "INSERT INTO www_companies (name,url,phone,fax,address,address2,zip) VALUES (?,?,?,?,?,?,?)" ) or do {
		# This should never happen if the above worked ok
		$self->{errstr} = "Failed to prepare SQL query: " . $self->{common}->{dbh}->errstr;
		return;
	};
	$sth->execute( $entity->{name}, $entity->{url}, $entity->{phone}, $entity->{fax}, $entity->{address}, $entity->{address2}, $entity->{zip} ) or do {
		# This may happen, if fed bad data or such
		$self->{errstr} = "Failed to execute SQL query: " . $self->{common}->{dbh}->errstr;
		$sth->finish;
		return;
	};
	$sth->finish;

	# Yay!
	return 1;
}

sub lookup_contact {
	my $self = shift;
	my $email = shift;

	$self->{errstr} = undef;

	if ( !$email ) {
		$self->{errstr} = "No email address given to lookup!";
		return;
	}

	my $sth = $self->{common}->{dbh}->prepare( "SELECT seq FROM www_contacts WHERE email = ?" ) or do {
		$self->{errstr} = "Failed to prepare SQL query: " . $self->{common}->{dbh}->errstr;
		return;
	};

	$sth->execute( lc( $email ) ) or do {
		$self->{errstr} = "Failed to execute SQL query: " . $self->{common}->{dbh}->errstr;
		$sth->finish;
		return;
	};

	my $entity = $sth->fetchrow_hashref;
	$sth->finish;

	return $entity->{seq} unless !$entity->{seq};
	return;
}

sub lookup_company {
	my $self = shift;
	my $name = shift;

	$self->{errstr} = undef;

	if ( !$name ) {
		$self->{errstr} = "No company given to lookup!";
		return;
	}

	my $sth = $self->{common}->{dbh}->prepare( "SELECT seq FROM www_companies WHERE name LIKE ?" ) or do {
		$self->{errstr} = "Failed to prepare SQL query: " . $self->{common}->{dbh}->errstr;
		return;
	};

	$sth->execute( "%$name%" ) or do {
		$self->{errstr} = "Failed to execute SQL query: " . $self->{common}->{dbh}->errstr;
		$sth->finish;
		return;
	};

	my $entity = $sth->fetchrow_hashref;
	$sth->finish;

	return $entity->{seq} unless !$entity->{seq};
	return;
}

sub get_contact_notes {
	my ( $self, $cid ) = @_;

	$self->{errstr} = undef;

	my $sth = $self->{common}->{dbh}->prepare( 'SELECT seq,ts,note FROM www_contact_notes WHERE contact = ?' ) or do {
		$self->{errstr} = 'Failed to prepare SQL query: ' . $self->{common}->{dbh}->errstr;
		return;
	};

	$sth->execute( $cid ) or do {
		$self->{errstr} = 'Failed to execute SQL query: ' . $self->{common}->{dbh}->errstr;
		$sth->finish;
		return;
	};

	my @results;
	while ( my $row = $sth->fetchrow_hashref ) {
		push ( @results, $row );
	}
	$sth->finish;

	return \@results;
}

sub insert_contact_notes {
	my ( $self, $contact, $note ) = @_;

	$self->{errstr} = undef;

	my $sth = $self->{common}->{dbh}->prepare( 'INSERT INTO www_contact_notes (contact,ts,note) VALUES (?,NOW()+0,?)' ) or do {
		$self->{errstr} = 'Failed to prepare SQL query: ' . $self->{common}->{dbh}->errstr;
		return;
	};

	$sth->execute( $contact, $note ) or do {
		$self->{errstr} = 'Failed to execute SQL query: ' . $self->{common}->{dbh}->errstr;
		$sth->finish;
		return;
	};

	$sth->finish;

	return 1;
}

sub insert_feedback {
	my $self = shift;
	my ( $contact, $message ) = @_;

	$self->{errstr} = undef;

	if ( !$contact ) {
		$self->{errstr} = "No contact given to insert feedback for!";
		return;
	}
	if ( !$message ) {
		$self->{errstr} = "No feedback message given to insert!";
		return;
	}

	my $sth = $self->{common}->{dbh}->prepare( "INSERT INTO www_feedback (contact,ts,comment) VALUES (?,NOW()+0,?)" ) or do {
		$self->{errstr} = "Failed to prepare SQL query: " . $self->{common}->{dbh}->errstr;
		return;
	};

	$sth->execute( $contact, $message ) or do {
		$self->{errstr} = "Failed to execute SQL query: " . $self->{common}->{dbh}->errstr;
		$sth->finish;
		return;
	};

	return 1;
}

sub insert_emergency {
	my $self = shift;
	my ( $contact, $message ) = @_;

	$self->{errstr} = undef;

	if ( !$contact ) {
		$self->{errstr} = "No contact given to insert feedback for!";
		return;
	}
	if ( !$message ) {
		$self->{errstr} = "No emergency message given to insert!";
		return;
	}

	my $sth = $self->{common}->{dbh}->prepare( "INSERT INTO www_emergency (contact,ts,message) VALUES (?,NOW()+0,?)" ) or do {
		$self->{errstr} = "Failed to prepare SQL query: " . $self->{common}->{dbh}->errstr;
		return;
	};

	$sth->execute( $contact, $message ) or do {
		$self->{errstr} = "Failed to execute SQL query: " . $self->{common}->{dbh}->errstr;
		$sth->finish;
		return;
	};

	return 1;
}

sub view_all_contacts {
	my $self = shift;

	$self->{errstr} = undef;

	my $sth = $self->{common}->{dbh}->prepare( "SELECT www_contacts.seq,prefix,fname,lname,name AS company,www_contacts.url,www_contacts.phone,ext,cell,email,www_contacts.fax,www_contacts.address,suite,city,state,www_zipcodes.zip,COUNT(note) AS count FROM www_contacts LEFT JOIN www_zipcodes ON www_contacts.zipcode = www_zipcodes.zip LEFT JOIN www_contact_notes ON www_contact_notes.contact = www_contacts.seq LEFT JOIN www_companies ON www_contacts.company = www_companies.seq GROUP BY www_contacts.seq ORDER BY count DESC" ) or do {
		$self->{errstr} = "Failed to prepare SQL query: " . $self->{common}->{dbh}->errstr;
		return;
	};

	$sth->execute() or do {
		$self->{errstr} = "Failed to execute SQL query: " . $self->{common}->{dbh}->errstr;
		$sth->finish;
		return;
	};

	my @results;

	while ( my $row = $sth->fetchrow_hashref ) {
		push ( @results, $row );
	}

	$sth->finish;

	return \@results;
}

sub view_all_companies {
	my $self = shift;

	$self->{errstr} = undef;

	my $sth = $self->{common}->{dbh}->prepare( "SELECT www_companies.seq,name,address,address2,city,state,www_companies.zip,url,phone,fax FROM www_companies LEFT JOIN www_zipcodes ON www_companies.zip = www_zipcodes.zip ORDER BY name" ) or do {
		$self->{errstr} = "Failed to prepare SQL query: " . $self->{common}->{dbh}->errstr;
		return;
	};

	$sth->execute() or do {
		$self->{errstr} = "Failed to execute SQL query: " . $self->{common}->{dbh}->errstr;
		$sth->finish;
		return;
	};

	my @results;

	while ( my $row = $sth->fetchrow_hashref ) {
		push ( @results, $row );
	}

	$sth->finish;

	return \@results;
}

sub find_contact {
	my ( $self, $crit ) = @_;

	$self->{errstr} = undef;

	my $sth = $self->{common}->{dbh}->prepare( 'SELECT www_contacts.seq,prefix,fname,lname,www_companies.seq AS company,www_companies.name AS companyName,www_contacts.url,www_contacts.phone,ext,cell,email,www_contacts.fax,www_contacts.address,www_contacts.suite,www_zipcodes.city,www_zipcodes.state,www_zipcodes.zip FROM www_contacts LEFT JOIN www_zipcodes ON www_contacts.zipcode = www_zipcodes.zip LEFT JOIN www_companies ON www_companies.seq = www_contacts.company WHERE www_companies.name LIKE ? OR www_contacts.address LIKE ? OR www_contacts.phone LIKE ? OR www_contacts.cell LIKE ? OR www_contacts.fname LIKE ? OR www_contacts.lname LIKE ? OR www_contacts.email LIKE ? OR www_zipcodes.city LIKE ? OR www_zipcodes.zip LIKE ? ORDER BY www_contacts.company,www_contacts.lname' ) or do {
		$self->{errstr} = 'Failed to prepare SQL query: ' . $self->{common}->{dbh}->errstr;
		return;
	};

	$sth->execute( "%$crit%", "%$crit%", "%$crit%", "%$crit%", "%$crit%", "%$crit%", "%$crit%", "%$crit%", "%$crit%" ) or do {
		$self->{errstr} = 'Failed to execute SQL query: ' . $self->{common}->{dbh}->errstr;
		$sth->finish;
		return;
	};
	my @results;

	while ( my $row = $sth->fetchrow_hashref ) {
		push ( @results, $row );
	}

	$sth->finish;

	return \@results;
}

sub find_company {
	my ( $self, $crit ) = @_;

	$self->{errstr} = undef;

	my $sth = $self->{common}->{dbh}->prepare( 'SELECT www_companies.seq AS seq,name,url,phone,fax,address,address2,city,state,www_companies.zip FROM www_companies LEFT JOIN www_zipcodes ON www_companies.zip = www_zipcodes.zip WHERE www_companies.name LIKE ? OR www_companies.url LIKE ? OR www_zipcodes.city LIKE ? OR www_zipcodes.state LIKE ? OR www_zipcodes.zip LIKE ? OR www_companies.phone LIKE ? OR www_companies.fax LIKE ? OR www_companies.address LIKE ? OR www_companies.address2 LIKE ? ORDER BY www_companies.name' ) or do {
		$self->{errstr} = 'Failed to prepare SQL query: ' . $self->{common}->{dbh}->errstr;
		return;
	};

	$sth->execute( "%$crit%", "%$crit%", "%$crit%", "%$crit%", "%$crit%", "%$crit%", "%$crit%", "%$crit%", "%$crit%" ) or do {
		$self->{errstr} = 'Failed to execute SQL query: ' . $self->{common}->{dbh}->errstr;
		$sth->finish;
		return;
	};
	my @results;

	while ( my $row = $sth->fetchrow_hashref ) {
		push ( @results, $row );
	}

	$sth->finish;

	return \@results;
}

sub update_contact_by_seq {
	my ( $self, $seq, $entity ) = @_;

	$self->{errstr} = undef;

	my $sth = $self->{common}->{dbh}->prepare( 'UPDATE www_contacts SET prefix = ?, fname = ?, lname = ?, email = ?, company = ?, url = ?, phone = ?, ext = ?, cell = ?, fax = ?, address = ?, suite = ?, zipcode = ?, prefer = ? WHERE seq = ? LIMIT 1' ) or do {
		$self->{errstr} = 'Failed to prepare SQL query: ' . $self->{common}->{dbh}->errstr;
		return;
	};

	$sth->execute( $entity->{prefix}, $entity->{fname}, $entity->{lname}, $entity->{email}, $entity->{company}, $entity->{url}, $entity->{phone}, $entity->{ext}, $entity->{cell}, $entity->{fax}, $entity->{address}, $entity->{suite}, $entity->{zipcode}, $entity->{prefer}, $seq ) or do {
		$self->{errstr} = 'Failed to execute SQL query: ' . $self->{common}->{dbh}->errstr;
		$sth->finish;
		return;
	};

	$sth->finish;
	return 1;
}

sub lookup_contact_by_seq {
	my ( $self, $seq ) = @_;

	$self->{errstr} = undef;

	my $sth = $self->{common}->{dbh}->prepare( 'SELECT www_contacts.seq AS seq,prefix,fname,lname,email,www_companies.seq AS company,www_companies.name AS companyName,www_contacts.url,www_contacts.phone,ext,cell,www_contacts.fax,www_contacts.address,www_contacts.suite,prefer,city,state,zipcode FROM www_contacts LEFT JOIN www_zipcodes ON www_contacts.zipcode = www_zipcodes.zip LEFT JOIN www_companies ON www_contacts.company = www_companies.seq WHERE www_contacts.seq = ? LIMIT 1' ) or do {
		$self->{errstr} = 'Failed to prepare SQL query: ' . $self->{common}->{dbh}->errstr;
		return;
	};

	$sth->execute( $seq ) or do {
		$self->{errstr} = 'Failed to execute SQL query: ' . $self->{common}->{dbh}->errstr;
		$sth->finish;
		return;
	};

	my $row = $sth->fetchrow_hashref;
	$sth->finish;

	return $row unless !$row;

	return;
}

sub delete_contact_by_seq {
	my ( $self, $seq ) = @_;

	$self->{errstr} = undef;
	my $sth = $self->{common}->{dbh}->prepare( 'DELETE FROM www_contacts WHERE seq = ? LIMIT 1' ) or do {
		$self->{errstr} = 'Failed to prepare SQL query: ' . $self->{common}->{dbh}->errstr;
		return;
	};

	$sth->execute( $seq ) or do {
		$self->{errstr} = 'Failed to execute SQL query: ' . $self->{common}->{dbh}->errstr;
		$sth->finish;
		return;
	};

	$sth->finish;

	return 1;
}

sub update_company_by_seq {
	my ( $self, $seq, $entity ) = @_;

	$self->{errstr} = undef;

	my $sth = $self->{common}->{dbh}->prepare( 'UPDATE www_companies SET name = ?, url = ?, phone = ?, fax = ?, address = ?, address2 = ?, zip = ? WHERE seq = ? LIMIT 1' ) or do {
		$self->{errstr} = 'Failed to prepare SQL query: ' . $self->{common}->{dbh}->errstr;
		return;
	};

	$sth->execute( $entity->{name}, $entity->{url}, $entity->{phone}, $entity->{fax}, $entity->{address}, $entity->{address2}, $entity->{zip}, $seq ) or do {
		$self->{errstr} = 'Failed to execute SQL query: ' . $self->{common}->{dbh}->errstr;
		$sth->finish;
		return;
	};

	$sth->finish;
	return 1;
}

sub lookup_company_by_seq {
	my ( $self, $seq ) = @_;

	$self->{errstr} = undef;

	my $sth = $self->{common}->{dbh}->prepare( 'SELECT www_companies.seq AS seq,name,url,phone,fax,address,address2,city,state,www_companies.zip FROM www_companies LEFT JOIN www_zipcodes ON www_companies.zip = www_zipcodes.zip WHERE www_companies.seq = ? LIMIT 1' ) or do {
		$self->{errstr} = 'Failed to prepare SQL query: ' . $self->{common}->{dbh}->errstr;
		return;
	};

	$sth->execute( $seq ) or do {
		$self->{errstr} = 'Failed to execute SQL query: ' . $self->{common}->{dbh}->errstr;
		$sth->finish;
		return;
	};

	my $row = $sth->fetchrow_hashref;
	$sth->finish;

	return $row unless !$row;

	return;
}

sub delete_company_by_seq {
	my ( $self, $seq ) = @_;

	$self->{errstr} = undef;
	my $sth = $self->{common}->{dbh}->prepare( 'DELETE FROM www_companies WHERE seq = ? LIMIT 1' ) or do {
		$self->{errstr} = 'Failed to prepare SQL query: ' . $self->{common}->{dbh}->errstr;
		return;
	};

	$sth->execute( $seq ) or do {
		$self->{errstr} = 'Failed to execute SQL query: ' . $self->{common}->{dbh}->errstr;
		$sth->finish;
		return;
	};

	$sth->finish;

	return 1;
}

sub lookup_note_by_seq {
	my ( $self, $seq ) = @_;

	$self->{errstr} = undef;

	my $sth = $self->{common}->{dbh}->prepare( 'SELECT seq,ts,note FROM www_contact_notes WHERE seq = ? LIMIT 1' ) or do {
		$self->{errstr} = 'Failed to prepare SQL query: ' . $self->{common}->{dbh}->errstr;
		return;
	};

	$sth->execute( $seq ) or do {
		$self->{errstr} = 'Failed to execute SQL query: ' . $self->{common}->{dbh}->errstr;
		$sth->finish;
		return;
	};

	my $row = $sth->fetchrow_hashref;
	$sth->finish;

	return $row unless !$row;

	return;
}

sub delete_note_by_seq {
	my ( $self, $seq ) = @_;

	$self->{errstr} = undef;

	my $sth = $self->{common}->{dbh}->prepare( 'DELETE FROM www_contact_notes WHERE seq = ? LIMIT 1' ) or do {
		$self->{errstr} = 'Failed to prepare SQL query: ' . $self->{common}->{dbh}->errstr;
		return;
	};

	$sth->execute( $seq ) or do {
		$self->{errstr} = 'Failed to execute SQL query: ' . $self->{common}->{dbh}->errstr;
		$sth->finish;
		return;
	};

	$sth->finish;

	return 1;
}

sub get_num_notes {
	my ( $self, $co ) = @_;

	$self->{errstr} = undef;

	my $sth = $self->{common}->{dbh}->prepare( 'SELECT seq FROM www_contact_notes WHERE contact = ?' ) or do {
		$self->{errstr} = 'Failed to prepare SQL query: ' . $self->{common}->{dbh}->errstr;
		return;
	};

	$sth->execute( $co ) or do {
		$self->{errstr} = 'Failed to execute SQL query: ' . $self->{common}->{dbh}->errstr;
		$sth->finish;
		return;
	};

	my $count = $sth->rows;

	$sth->finish;
	return $count if $count;
	return 0;
}

1;
