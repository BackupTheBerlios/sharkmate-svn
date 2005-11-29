#!/usr/bin/perl

package Contacts;

use warnings;
use strict;
use POSIX qw( strftime );

sub new {
	my $class = shift;
	my $self = { };
	bless $self, $class;

	$self->{dispatch} = {
		'0000'		=>	\&display_all_contacts,			# Moved
		'0001'		=>	\&display_find_contacts,		# Moved
		'0010'		=>	\&display_add_contact,			# Moved
		'0011'		=>	\&display_edit_contact,			# Moved
		'0100'		=>	\&display_contact_notes,		# Moved
		'0101'		=>	\&display_delete_contact,		# Moved
		'0110'		=>	\&display_insert_contact_note,
		'0111'		=>	\&display_delete_contact_note,
		'1000'		=>	\&display_all_companies,
		'00010000'	=>	\&display_delete_company,
		'00010001'	=>	\&display_edit_company,
		'1001'		=>	\&display_find_company,
		'1010'		=>	\&display_add_company,
	};

	return $self;
}

## Start of low-level functions
#

sub insert_contact {
	my ( $self, $dbh, $entity ) = @_;

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
	my $sth = $dbh->prepare( "INSERT INTO www_contacts (prefix,fname,lname,email,company,url,phone,ext,cell,fax,prefer,address,suite,zipcode) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)" ) or do {
		# This should never happen if the above worked ok
		$self->{errstr} = "Failed to prepare SQL query: " . $dbh->errstr;
		return;
	};
	$sth->execute( $entity->{prefix}, $entity->{fname}, $entity->{lname}, lc( $entity->{email} ), $entity->{company}, $entity->{url}, $entity->{phone}, $entity->{ext}, $entity->{cell}, $entity->{fax}, $entity->{prefer}, $entity->{address}, $entity->{suite}, $entity->{zip} ) or do {
		# This may happen, if fed bad data or such
		$self->{errstr} = "Failed to execute SQL query: " . $dbh->errstr;
		$sth->finish;
		return;
	};
	$sth->finish;

	# Yay!
	return 1;
}

sub insert_company {
	my ( $self, $dbh, $entity ) = @_;

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
	my $sth = $dbh->prepare( "INSERT INTO www_companies (name,url,phone,fax,address,address2,zip) VALUES (?,?,?,?,?,?,?)" ) or do {
		# This should never happen if the above worked ok
		$self->{errstr} = "Failed to prepare SQL query: " . $dbh->errstr;
		return;
	};
	$sth->execute( $entity->{name}, $entity->{url}, $entity->{phone}, $entity->{fax}, $entity->{address}, $entity->{address2}, $entity->{zip} ) or do {
		# This may happen, if fed bad data or such
		$self->{errstr} = "Failed to execute SQL query: " . $dbh->errstr;
		$sth->finish;
		return;
	};
	$sth->finish;

	# Yay!
	return 1;
}

sub lookup_contact {
	my ( $self, $dbh, $email ) = @_;

	$self->{errstr} = undef;

	if ( !$email ) {
		$self->{errstr} = "No email address given to lookup!";
		return;
	}

	my $sth = $dbh->prepare( "SELECT seq FROM www_contacts WHERE email = ?" ) or do {
		$self->{errstr} = "Failed to prepare SQL query: " . $dbh->errstr;
		return;
	};

	$sth->execute( lc( $email ) ) or do {
		$self->{errstr} = "Failed to execute SQL query: " . $dbh->errstr;
		$sth->finish;
		return;
	};

	my $entity = $sth->fetchrow_hashref;
	$sth->finish;

	return $entity->{seq} unless !$entity->{seq};
	return;
}

sub lookup_company {
	my ( $self, $dbh, $name ) = @_;

	$self->{errstr} = undef;

	if ( !$name ) {
		$self->{errstr} = "No company given to lookup!";
		return;
	}

	my $sth = $dbh->prepare( "SELECT seq FROM www_companies WHERE name LIKE ?" ) or do {
		$self->{errstr} = "Failed to prepare SQL query: " . $dbh->errstr;
		return;
	};

	$sth->execute( "%$name%" ) or do {
		$self->{errstr} = "Failed to execute SQL query: " . $dbh->errstr;
		$sth->finish;
		return;
	};

	my $entity = $sth->fetchrow_hashref;
	$sth->finish;

	return $entity->{seq} unless !$entity->{seq};
	return;
}

sub get_contact_notes {
	my ( $self, $dbh, $cid ) = @_;

	$self->{errstr} = undef;

	my $sth = $dbh->prepare( 'SELECT seq,ts,note FROM www_contact_notes WHERE contact = ?' ) or do {
		$self->{errstr} = 'Failed to prepare SQL query: ' . $dbh->errstr;
		return;
	};

	$sth->execute( $cid ) or do {
		$self->{errstr} = 'Failed to execute SQL query: ' . $dbh->errstr;
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
	my ( $self, $dbh, $contact, $note ) = @_;

	$self->{errstr} = undef;

	my $sth = $dbh->prepare( 'INSERT INTO www_contact_notes (contact,ts,note) VALUES (?,NOW()+0,?)' ) or do {
		$self->{errstr} = 'Failed to prepare SQL query: ' . $dbh->errstr;
		return;
	};

	$sth->execute( $contact, $note ) or do {
		$self->{errstr} = 'Failed to execute SQL query: ' . $dbh->errstr;
		$sth->finish;
		return;
	};

	$sth->finish;

	return 1;
}

sub insert_feedback {
	my ( $self, $dbh, $contact, $message ) = @_;

	$self->{errstr} = undef;

	if ( !$contact ) {
		$self->{errstr} = "No contact given to insert feedback for!";
		return;
	}
	if ( !$message ) {
		$self->{errstr} = "No feedback message given to insert!";
		return;
	}

	my $sth = $dbh->prepare( "INSERT INTO www_feedback (contact,ts,comment) VALUES (?,NOW()+0,?)" ) or do {
		$self->{errstr} = "Failed to prepare SQL query: " . $dbh->errstr;
		return;
	};

	$sth->execute( $contact, $message ) or do {
		$self->{errstr} = "Failed to execute SQL query: " . $dbh->errstr;
		$sth->finish;
		return;
	};

	return 1;
}

sub insert_emergency {
	my ( $self, $dbh, $contact, $message ) = @_;

	$self->{errstr} = undef;

	if ( !$contact ) {
		$self->{errstr} = "No contact given to insert feedback for!";
		return;
	}
	if ( !$message ) {
		$self->{errstr} = "No emergency message given to insert!";
		return;
	}

	my $sth = $dbh->prepare( "INSERT INTO www_emergency (contact,ts,message) VALUES (?,NOW()+0,?)" ) or do {
		$self->{errstr} = "Failed to prepare SQL query: " . $dbh->errstr;
		return;
	};

	$sth->execute( $contact, $message ) or do {
		$self->{errstr} = "Failed to execute SQL query: " . $dbh->errstr;
		$sth->finish;
		return;
	};

	return 1;
}

sub view_all_contacts {
	my ( $self, $dbh ) = @_;

	$self->{errstr} = undef;

	my $sth = $dbh->prepare( "SELECT www_contacts.seq,prefix,fname,lname,name AS company,www_contacts.url,www_contacts.phone,ext,cell,email,www_contacts.fax,www_contacts.address,suite,city,state,www_zipcodes.zip,COUNT(note) AS count FROM www_contacts LEFT JOIN www_zipcodes ON www_contacts.zipcode = www_zipcodes.zip LEFT JOIN www_contact_notes ON www_contact_notes.contact = www_contacts.seq LEFT JOIN www_companies ON www_contacts.company = www_companies.seq GROUP BY www_contacts.seq ORDER BY count DESC" ) or do {
		$self->{errstr} = "Failed to prepare SQL query: " . $dbh->errstr;
		return;
	};

	$sth->execute() or do {
		$self->{errstr} = "Failed to execute SQL query: " . $dbh->errstr;
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
	my ( $self, $dbh ) = @_;

	$self->{errstr} = undef;

	my $sth = $dbh->prepare( "SELECT www_companies.seq,name,address,address2,city,state,www_companies.zip,url,phone,fax FROM www_companies LEFT JOIN www_zipcodes ON www_companies.zip = www_zipcodes.zip ORDER BY name" ) or do {
		$self->{errstr} = "Failed to prepare SQL query: " . $dbh->errstr;
		return;
	};

	$sth->execute() or do {
		$self->{errstr} = "Failed to execute SQL query: " . $dbh->errstr;
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
	my ( $self, $dbh, $crit ) = @_;

	$self->{errstr} = undef;

	my $sth = $dbh->prepare( 'SELECT www_contacts.seq,prefix,fname,lname,www_companies.seq AS company,www_companies.name AS companyName,www_contacts.url,www_contacts.phone,ext,cell,email,www_contacts.fax,www_contacts.address,www_contacts.suite,www_zipcodes.city,www_zipcodes.state,www_zipcodes.zip FROM www_contacts LEFT JOIN www_zipcodes ON www_contacts.zipcode = www_zipcodes.zip LEFT JOIN www_companies ON www_companies.seq = www_contacts.company WHERE www_companies.name LIKE ? OR www_contacts.address LIKE ? OR www_contacts.phone LIKE ? OR www_contacts.cell LIKE ? OR www_contacts.fname LIKE ? OR www_contacts.lname LIKE ? OR www_contacts.email LIKE ? OR www_zipcodes.city LIKE ? OR www_zipcodes.zip LIKE ? ORDER BY www_contacts.company,www_contacts.lname' ) or do {
		$self->{errstr} = 'Failed to prepare SQL query: ' . $dbh->errstr;
		return;
	};

	$sth->execute( "%$crit%", "%$crit%", "%$crit%", "%$crit%", "%$crit%", "%$crit%", "%$crit%", "%$crit%", "%$crit%" ) or do {
		$self->{errstr} = 'Failed to execute SQL query: ' . $dbh->errstr;
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
	my ( $self, $dbh, $crit ) = @_;

	$self->{errstr} = undef;

	my $sth = $dbh->prepare( 'SELECT www_companies.seq AS seq,name,url,phone,fax,address,address2,city,state,www_companies.zip FROM www_companies LEFT JOIN www_zipcodes ON www_companies.zip = www_zipcodes.zip WHERE www_companies.name LIKE ? OR www_companies.url LIKE ? OR www_zipcodes.city LIKE ? OR www_zipcodes.state LIKE ? OR www_zipcodes.zip LIKE ? OR www_companies.phone LIKE ? OR www_companies.fax LIKE ? OR www_companies.address LIKE ? OR www_companies.address2 LIKE ? ORDER BY www_companies.name' ) or do {
		$self->{errstr} = 'Failed to prepare SQL query: ' . $dbh->errstr;
		return;
	};

	$sth->execute( "%$crit%", "%$crit%", "%$crit%", "%$crit%", "%$crit%", "%$crit%", "%$crit%", "%$crit%", "%$crit%" ) or do {
		$self->{errstr} = 'Failed to execute SQL query: ' . $dbh->errstr;
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
	my ( $self, $dbh, $seq, $entity ) = @_;

	$self->{errstr} = undef;

	my $sth = $dbh->prepare( 'UPDATE www_contacts SET prefix = ?, fname = ?, lname = ?, email = ?, company = ?, url = ?, phone = ?, ext = ?, cell = ?, fax = ?, address = ?, suite = ?, zipcode = ?, prefer = ? WHERE seq = ? LIMIT 1' ) or do {
		$self->{errstr} = 'Failed to prepare SQL query: ' . $dbh->errstr;
		return;
	};

	$sth->execute( $entity->{prefix}, $entity->{fname}, $entity->{lname}, $entity->{email}, $entity->{company}, $entity->{url}, $entity->{phone}, $entity->{ext}, $entity->{cell}, $entity->{fax}, $entity->{address}, $entity->{suite}, $entity->{zipcode}, $entity->{prefer}, $seq ) or do {
		$self->{errstr} = 'Failed to execute SQL query: ' . $dbh->errstr;
		$sth->finish;
		return;
	};

	$sth->finish;
	return 1;
}

sub lookup_contact_by_seq {
	my ( $self, $dbh, $seq ) = @_;

	$self->{errstr} = undef;

	my $sth = $dbh->prepare( 'SELECT www_contacts.seq AS seq,prefix,fname,lname,email,www_companies.seq AS company,www_companies.name AS companyName,www_contacts.url,www_contacts.phone,ext,cell,www_contacts.fax,www_contacts.address,www_contacts.suite,prefer,city,state,zipcode FROM www_contacts LEFT JOIN www_zipcodes ON www_contacts.zipcode = www_zipcodes.zip LEFT JOIN www_companies ON www_contacts.company = www_companies.seq WHERE www_contacts.seq = ? LIMIT 1' ) or do {
		$self->{errstr} = 'Failed to prepare SQL query: ' . $dbh->errstr;
		return;
	};

	$sth->execute( $seq ) or do {
		$self->{errstr} = 'Failed to execute SQL query: ' . $dbh->errstr;
		$sth->finish;
		return;
	};

	my $row = $sth->fetchrow_hashref;
	$sth->finish;

	return $row unless !$row;

	return;
}

sub delete_contact_by_seq {
	my ( $self, $dbh, $seq ) = @_;

	$self->{errstr} = undef;
	my $sth = $dbh->prepare( 'DELETE FROM www_contacts WHERE seq = ? LIMIT 1' ) or do {
		$self->{errstr} = 'Failed to prepare SQL query: ' . $dbh->errstr;
		return;
	};

	$sth->execute( $seq ) or do {
		$self->{errstr} = 'Failed to execute SQL query: ' . $dbh->errstr;
		$sth->finish;
		return;
	};

	$sth->finish;

	return 1;
}

sub update_company_by_seq {
	my ( $self, $dbh, $seq, $entity ) = @_;

	$self->{errstr} = undef;

	my $sth = $dbh->prepare( 'UPDATE www_companies SET name = ?, url = ?, phone = ?, fax = ?, address = ?, address2 = ?, zip = ? WHERE seq = ? LIMIT 1' ) or do {
		$self->{errstr} = 'Failed to prepare SQL query: ' . $dbh->errstr;
		return;
	};

	$sth->execute( $entity->{name}, $entity->{url}, $entity->{phone}, $entity->{fax}, $entity->{address}, $entity->{address2}, $entity->{zip}, $seq ) or do {
		$self->{errstr} = 'Failed to execute SQL query: ' . $dbh->errstr;
		$sth->finish;
		return;
	};

	$sth->finish;
	return 1;
}

sub lookup_company_by_seq {
	my ( $self, $dbh, $seq ) = @_;

	$self->{errstr} = undef;

	my $sth = $dbh->prepare( 'SELECT www_companies.seq AS seq,name,url,phone,fax,address,address2,city,state,www_companies.zip FROM www_companies LEFT JOIN www_zipcodes ON www_companies.zip = www_zipcodes.zip WHERE www_companies.seq = ? LIMIT 1' ) or do {
		$self->{errstr} = 'Failed to prepare SQL query: ' . $dbh->errstr;
		return;
	};

	$sth->execute( $seq ) or do {
		$self->{errstr} = 'Failed to execute SQL query: ' . $dbh->errstr;
		$sth->finish;
		return;
	};

	my $row = $sth->fetchrow_hashref;
	$sth->finish;

	return $row unless !$row;

	return;
}

sub delete_company_by_seq {
	my ( $self, $dbh, $seq ) = @_;

	$self->{errstr} = undef;
	my $sth = $dbh->prepare( 'DELETE FROM www_companies WHERE seq = ? LIMIT 1' ) or do {
		$self->{errstr} = 'Failed to prepare SQL query: ' . $dbh->errstr;
		return;
	};

	$sth->execute( $seq ) or do {
		$self->{errstr} = 'Failed to execute SQL query: ' . $dbh->errstr;
		$sth->finish;
		return;
	};

	$sth->finish;

	return 1;
}

sub lookup_note_by_seq {
	my ( $self, $dbh, $seq ) = @_;

	$self->{errstr} = undef;

	my $sth = $dbh->prepare( 'SELECT seq,ts,note FROM www_contact_notes WHERE seq = ? LIMIT 1' ) or do {
		$self->{errstr} = 'Failed to prepare SQL query: ' . $dbh->errstr;
		return;
	};

	$sth->execute( $seq ) or do {
		$self->{errstr} = 'Failed to execute SQL query: ' . $dbh->errstr;
		$sth->finish;
		return;
	};

	my $row = $sth->fetchrow_hashref;
	$sth->finish;

	return $row unless !$row;

	return;
}

sub delete_note_by_seq {
	my ( $self, $dbh, $seq ) = @_;

	$self->{errstr} = undef;

	my $sth = $dbh->prepare( 'DELETE FROM www_contact_notes WHERE seq = ? LIMIT 1' ) or do {
		$self->{errstr} = 'Failed to prepare SQL query: ' . $dbh->errstr;
		return;
	};

	$sth->execute( $seq ) or do {
		$self->{errstr} = 'Failed to execute SQL query: ' . $dbh->errstr;
		$sth->finish;
		return;
	};

	$sth->finish;

	return 1;
}

sub get_num_notes {
	my ( $self, $dbh, $co ) = @_;

	$self->{errstr} = undef;

	my $sth = $dbh->prepare( 'SELECT seq FROM www_contact_notes WHERE contact = ?' ) or do {
		$self->{errstr} = 'Failed to prepare SQL query: ' . $dbh->errstr;
		return;
	};

	$sth->execute( $co ) or do {
		$self->{errstr} = 'Failed to execute SQL query: ' . $dbh->errstr;
		$sth->finish;
		return;
	};

	my $count = $sth->rows;

	$sth->finish;
	return $count if $count;
	return 0;
}

#
## End of low-level functions

## Start of high-level functions
#

sub display_all_contacts {
	my ( $self, $dbh, $q ) = @_;

	my %prefixes = (
		1 => 'Mr.',
		2 => 'Ms.',
		3 => 'Mrs.',
		4 => 'Dr.',
	);

	my @out;

	push ( @out,  $q->h3( "View all contacts" ) );
	push ( @out,  $q->hr({ -class => 'mini'}) );
	push ( @out,  $q->br );
	my $contacts = $self->view_all_contacts( $self, $dbh );
	my $matches = scalar( @{ $contacts } );
	push ( @out,  $q->start_div({ -align => 'center' }) );
	if ( $matches < 1 ) {
		push ( @out,  "Sorry, there are no contacts in the database." );
		push ( @out,  $q->end_div );
	}
	else {
		push ( @out,  "There is $matches contact on record" ) if $matches <= 1;
		push ( @out,  "There are " . commie( $matches ) . " contacts on record" ) if $matches > 1;
		push ( @out,  $q->end_div );
		push ( @out,  $q->br );
		my $count;
		foreach my $contact ( @{ $contacts } ) {
			$count++;
			(my $company = $contact->{company}) =~ s/($vars->{crit})/\<b\>\<u\>$1\<\/u\>\<\/b\>/gi;
			(my $fname = $contact->{fname}) =~ s/($vars->{crit})/\<b\>\<u\>$1\<\/u\>\<\/b\>/gi;
			(my $lname = $contact->{lname}) =~ s/($vars->{crit})/\<b\>\<u\>$1\<\/u\>\<\/b\>/gi;
			(my $email = $contact->{email}) =~ s/($vars->{crit})/\<b\>\<u\>$1\<\/u\>\<\/b\>/gi;
			(my $city = $contact->{city}) =~ s/($vars->{crit})/\<b\>\<u\>$1\<\/u\>\<\/b\>/gi;
			push ( @out,  $q->start_div({ -class => 'block' }) );
			push ( @out,  $q->start_div({ -class => 'block-title' }) );
			push ( @out,  $company );
			push ( @out,  $q->end_div );
			push ( @out,  $q->start_ul({ -class => 'sleek' }) );
			push ( @out,  $q->start_li . $prefixes{$contact->{prefix}} . ' ' . join( ", ", $lname, $fname ) . $q->end_li );
			push ( @out,  $q->start_li . 'url: ' . $contact->{url} . $q->end_li ) if $contact->{url};
			push ( @out,  $q->br );
			push ( @out,  $q->start_li . $contact->{address} . $q->end_li );
			push ( @out,  $q->start_li . $contact->{suite} . $q->end_li ) if $contact->{suite};
			push ( @out,  $q->start_li . join ( ", ", $city, $contact->{state}, $contact->{zip} ) . $q->end_li );
			push ( @out,  $q->br );
			push ( @out,  $q->start_li . 'em: ' . $email . $q->end_li );
			push ( @out,  $q->start_li . 'ph: ' . $contact->{phone} );
			push ( @out,  " x " . $contact->{ext} ) if $contact->{ext};
			push ( @out,  $q->end_li );
			push ( @out,  $q->start_li . 'ce: ' . $contact->{cell} . $q->end_li ) if $contact->{cell};
			push ( @out,  $q->start_li . 'fx: ' . $contact->{fax} . $q->end_li ) if $contact->{fax};
			push ( @out,  $q->start_div({ -align => 'center' }) );
			push ( @out,  '[ ' . $q->a({ -href => $q->url . '?act=0101;co=' . $contact->{seq} }, "delete" ) . ' ]' );
			push ( @out,  '[ ' . $q->a({ -href => $q->url . '?act=0011;co=' . $contact->{seq} }, "edit" ) . ' ]' );
			push ( @out,  '[ ' . $q->a({ -href => 'mailto:' . $contact->{email} }, "e-mail" ) . ' ]' );
			push ( @out,  '[ ' . $q->a({ -href => $q->url . '?act=0100;co=' . $contact->{seq} }, $self->get_num_notes( $contact->{seq} ) . " notes" ) . ' ]' );
			push ( @out,  '[ ' . $q->a({ -href => $contact->{url} }, "website" ) . ' ]' ) if $contact->{url};
			push ( @out,  $q->end_div );
			push ( @out,  $q->end_ul );
			push ( @out,  $q->end_div );
			push ( @out,  $q->br );
		}
	}
	push ( @out,  $q->hr({ -class => 'mini' }) );
	push ( @out,  $q->br );

	return \@out;
}

sub display_find_contacts {
	my ( $self, $q ) = @_;

	my @out;

	push ( @out,  $q->h3( "Find Contacts" ) );
	push ( @out,  $q->hr({ -class => 'mini'}) );
	push ( @out,  $q->start_form );
	push ( @out,  $q->hidden(	-name		=> 'act',
					-value		=> '0001',
					-override	=> 1	) );
	push ( @out,  $q->start_div({	-align	=> 'center' }) );
	push ( @out,  $q->textfield(	-class	=> 'sleek-small',
					-name	=> 'crit',
					-value	=> ''		) );
	push ( @out,  $q->submit(	-class	=> 'sleek-button',
					-value	=> 'Find!'	) );
	push ( @out,  $q->end_div );
	push ( @out,  $q->end_form );
	if ( $vars->{crit} ) {
		my $contacts = $self->find_contact( $vars->{crit} );
		my $matches = scalar( @{$contacts} );
		if ( $matches < 1 ) {
			push ( @out,  $q->start_div({ -align => 'center' }) );
			push ( @out,  "Found no matches for: '$vars->{crit}'" );
			push ( @out,  $q->end_div );
		}
		else {
			push ( @out,  $q->start_div({ -align => 'center' }) );
			if ( $matches > 1 ) {
				push ( @out,  "Found " . commie( $matches ) . " matches" );
			}
			else {
				push ( @out,  "Found $matches match" );
			}
			push ( @out,  " for: '$vars->{crit}'" );
			push ( @out,  $q->end_div );
			my %prefixes = (
				1 => 'Mr.',
				2 => 'Ms.',
				3 => 'Mrs.',
				4 => 'Dr.',
			);
			my $count;
			foreach my $contact ( @{ $contacts } ) {
				$count++;
				(my $company = $contact->{companyName}) =~ s/($vars->{crit})/\<b\>\<u\>$1\<\/u\>\<\/b\>/gi;
				(my $address = $contact->{address}) =~ s/($vars->{crit})/\<b\>\<u\>$1\<\/u\>\<\/b\>/gi;
				(my $suite = $contact->{suite}) =~ s/($vars->{crit})/\<b\>\<u\>$1\<\/u\>\<\/b\>/gi if $contact->{suite};
				(my $url = $contact->{url}) =~ s/($vars->{crit})/\<b\>\<u\>$1\<\/u\>\<\/b\>/gi if $contact->{url};
				(my $fname = $contact->{fname}) =~ s/($vars->{crit})/\<b\>\<u\>$1\<\/u\>\<\/b\>/gi;
				(my $lname = $contact->{lname}) =~ s/($vars->{crit})/\<b\>\<u\>$1\<\/u\>\<\/b\>/gi;
				(my $email = $contact->{email}) =~ s/($vars->{crit})/\<b\>\<u\>$1\<\/u\>\<\/b\>/gi;
				(my $city = $contact->{city}) =~ s/($vars->{crit})/\<b\>\<u\>$1\<\/u\>\<\/b\>/gi;
				(my $zip = $contact->{zip}) =~ s/($vars->{crit})/\<b\>\<u\>$1\<\/u\>\<\/b\>/gi;
				(my $phone = $contact->{phone}) =~ s/($vars->{crit})/\<b\>\<u\>$1\<\/u\>\<\/b\>/gi;
				(my $ext = $contact->{ext}) =~ s/($vars->{crit})/\<b\>\<u\>$1\<\/u\>\<\/b\>/gi if $contact->{ext};
				(my $cell = $contact->{cell}) =~ s/($vars->{crit})/\<b\>\<u\>$1\<\/u\>\<\/b\>/gi if $contact->{cell};
				(my $fax = $contact->{cell}) =~ s/($vars->{crit})/\<b\>\<u\>$1\<\/u\>\<\/b\>/gi if $contact->{fax};
				push ( @out,  $q->start_div({ -class => 'block' }) );
				push ( @out,  $q->start_div({ -class => 'block-title' }) );
				push ( @out,  $company );
				push ( @out,  $q->end_div );
				push ( @out,  $q->start_ul({ -class => 'sleek' }) );
				push ( @out,  $q->start_li . $prefixes{$contact->{prefix}} . ' ' . join( ", ", $lname, $fname ) . $q->end_li );
				push ( @out,  $q->start_li . $url . $q->end_li ) if $url;
				push ( @out,  $q->br );
				push ( @out,  $q->start_li . $address . $q->end_li );
				push ( @out,  $q->start_li . $suite . $q->end_li ) if $suite;
				push ( @out,  $q->start_li . join ( ", ", $city, $contact->{state}, $zip ) . $q->end_li );
				push ( @out,  $q->br );
				push ( @out,  $q->start_li . 'em: ' . $email . $q->end_li );
				push ( @out,  $q->start_li . 'ph: ' . $phone );
				push ( @out,  " x " . $ext ) if $ext;
				push ( @out,  $q->end_li );
				push ( @out,  $q->start_li . 'ce: ' . $cell . $q->end_li . $q->br ) if $cell;
				push ( @out,  $q->start_li . 'fx: ' . $fax . $q->end_li ) if $fax;
				push ( @out,  $q->start_div({ -align => 'center' }) );
				push ( @out,  '[ ' . $q->a({ -href => $q->url . '?act=0101;co=' . $contact->{seq} }, "delete" ) . ' ]' );
				push ( @out,  '[ ' . $q->a({ -href => $q->url . '?act=0011;co=' . $contact->{seq} }, "edit" ) . ' ]' );
				push ( @out,  '[ ' . $q->a({ -href => 'mailto:' . $contact->{email} }, "e-mail" ) . ' ]' );
				push ( @out,  '[ ' . $q->a({ -href => $q->url . '?act=0100;co=' . $contact->{seq} }, $self->get_num_notes( $contact->{seq} ) . " notes" ) . ' ]' );
				push ( @out,  '[ ' . $q->a({ -href => $contact->{url} }, "website" ) . ' ]' ) if $contact->{url};
				push ( @out,  $q->end_div );
				push ( @out,  $q->end_div );
				push ( @out,  $q->br );
			}
		}
	}
	push ( @out,  $q->hr({ -class => 'mini' }) );
	push ( @out,  $q->br );

	return \@out;
}

sub display_add_contact {
	my ( $self, $q, $dbh ) = @_;

	my @out;

	push ( @out,  $q->h3( "Add Contact" ) );
	push ( @out,  $q->hr({ -class => 'mini' }) );
	push ( @out,  $q->br );
	if ( $vars->{prefix} && $vars->{fname} && $vars->{lname} && $vars->{company} && $vars->{zip} && $vars->{phone} && $vars->{address} && $vars->{email} && $vars->{prefer} ) {
		my %entity = (
			prefix => $vars->{prefix},
			fname => $vars->{fname},
			lname => $vars->{lname},
			company => $vars->{company},
			url => $vars->{url},
			address => $vars->{address},
			suite => $vars->{suite},
			zip => $vars->{zip},
			email => $vars->{email},
			phone => $vars->{phone},
			ext => $vars->{ext},
			fax => $vars->{fax},
			cell => $vars->{cell},
			prefer => $vars->{prefer},
		);
		my $ret = $self->insert_contact( \%entity );
		if ( !$ret ) {
			push ( @out, "OH NOES! YOUR POP3 HAS BEEN IMAP'ed: " . $self->{errstr} );
		}
		else {
			push ( @out, "Contact successfully added!" );
			push ( @out, $q->br );
		}
	}
	else {
		my $companies = $wo->get_all_companies();
		my %prefixes = (
			1 => 'Mr.',
			2 => 'Ms.',
			3 => 'Mrs.',
			4 => 'Dr.',
		);
		my %pcont = (
			1 => 'E-Mail',
			2 => 'Phone',
			3 => 'Postal Mail',
		);
		push ( @out,  $q->start_form );
		push ( @out,  $q->hidden({
			-name => 'act',
			-value => '0010',
			-override => 1,
		}) );
		push ( @out,  '<label class="sleek-bold" for="prefix">Salutation:</label>' );
		push ( @out,  $q->popup_menu(
			-name => 'prefix',
			-values => \%prefixes,
			-labels => \%prefixes,
			-class => 'sleek',
		) );
		push ( @out,  $q->br );
		push ( @out,  '<label class="sleek-bold" for="fname">First Name:</label>' );
		push ( @out,  $q->textfield(
			-name => 'fname',
			-id => 'fname',
			-class => 'sleek',
			-maxlength => 16,
		) );
		push ( @out,  $q->br );
		push ( @out,  '<label class="sleek-bold" for="lname">Last Name:</label>' );
			push ( @out,  $q->textfield(
			-name => 'lname',
			-id => 'lname',
			-class => 'sleek',
			-maxlength => 16,
		) );
		push ( @out,  $q->br );
		push ( @out,  '<label class="sleek-bold" for="email">E-Mail:</label>' );
		push ( @out,  $q->textfield(
			-name => 'email',
			-id => 'email',
			-class => 'sleek',
			-maxlength => 48,
		) );
		push ( @out,  $q->br );
		push ( @out,  $q->hr({ -class => 'mini' }) );
		push ( @out,  '<label class="sleek-bold" for="company">Company:</label>' );
		push ( @out,  $q->popup_menu(
			-name => 'company',
			-id => 'company',
			-class => 'sleek-large',
			-values => $companies,
			-labels => $companies,
		) );
		push ( @out,  $q->br );
		push ( @out,  '<label class="sleek-bold" for="url">URL:</label>' );
		push ( @out,  $q->textfield(
			-name => 'url',
			-id => 'url',
			-class => 'sleek',
			-maxlength => 255,
		) );
		push ( @out,  $q->br );
		push ( @out,  '<label class="sleek-bold" for="phone">Phone:</label>' );
		push ( @out,  $q->textfield(
			-name => 'phone',
			-id => 'phone',
			-class => 'sleek',
			-maxlength => 16,
		) );
		push ( @out,  $q->br );
		push ( @out,  '<label class="sleek" for="ext">Extension:</label>' );
		push ( @out,  $q->textfield(
			-name => 'ext',
			-id => 'ext',
			-class => 'sleek-small',
			-maxlength => 6,
		) );
		push ( @out,  $q->br );
		push ( @out,  '<label class="sleek" for="cell">Cell:</label>' );
		push ( @out,  $q->textfield(
			-name => 'cell',
			-id => 'cell',
			-class => 'sleek',
			-maxlength => 16,
		) );
		push ( @out,  $q->br );
		push ( @out,  '<label class="sleek" for="fax">Fax:</label>' );
		push ( @out,  $q->textfield(
			-name => 'fax',
			-id => 'fax',
			-class => 'sleek',
			-maxlength => 16,
		) );
		push ( @out,  $q->br );
		push ( @out,  '<label class="sleek-bold" for="address">Street Address:</label>' );
		push ( @out,  $q->textfield(
			-name => 'address',
			-id => 'address',
			-class => 'sleek',
			-maxlength => 48,
		) );
		push ( @out,  $q->br );
		push ( @out,  '<label class="sleek" for="suite">Suite:</label>' );
		push ( @out,  $q->textfield(
			-name => 'suite',
			-id => 'suite',
			-class => 'sleek-small',
			-maxlength => 12,
		) );
		push ( @out,  $q->br );
		push ( @out,  '<label class="sleek-bold" for="zip">Zipcode:</label>' );
		push ( @out,  $q->textfield(
			-name => 'zip',
			-id => 'zip',
			-class => 'sleek-small',
			-maxlength => 5,
		) );
		push ( @out,  $q->br );
		push ( @out,  $q->hr({ -class => 'mini' }) );
		push ( @out,  '<label class="sleek-bold" for="prefer">Prefer Contact Via:</label>' );
		push ( @out,  $q->popup_menu(
			-name => 'prefer',
			-values => \%pcont,
			-labels => \%pcont,
			-class => 'sleek',
		) );
		push ( @out,  $q->br );
		push ( @out,  $q->hr({ -class => 'mini' }) );
		push ( @out,  $q->start_div({ -class => 'sleek-button' }) );
		push ( @out,  $q->submit({
			-class => 'sleek-button',
			-value => 'Add!',
			-id => 'submit',
			-name => 'submit',
		}) );
		push ( @out,  $q->end_div );
		push ( @out,  $q->end_form );
	}
	push ( @out,  $q->br );
	push ( @out,  $q->hr({ -class => 'mini' }) );
	push ( @out,  $q->br );
}

sub display_edit_contact {
	my ( $self, $q, $dbh ) = @_;

	my @out;

	push ( @out,  $q->h3( "Edit Contact" ) );
	push ( @out,  $q->hr({ -class => 'mini' }) );
	push ( @out,  $q->br );
	if ( $vars->{prefix} && $vars->{fname} && $vars->{lname} && $vars->{company} && $vars->{zip} && $vars->{phone} && $vars->{address} && $vars->{email} && $vars->{prefer} && $self->lookup_contact_by_seq( $vars->{co} ) ) {
		my %entity = (
			prefix => $vars->{prefix},
			fname => $vars->{fname},
			lname => $vars->{lname},
			company => $vars->{company},
			url => $vars->{url},
			address => $vars->{address},
			suite => $vars->{suite},
			zip => $vars->{zip},
			email => $vars->{email},
			phone => $vars->{phone},
			ext => $vars->{ext},
			cell => $vars->{cell},
			fax => $vars->{fax},
			zipcode => $vars->{zip},
			prefer => $vars->{prefer},
		);
		my $ret = $self->update_contact_by_seq( $vars->{co}, \%entity );
		if ( !$ret ) {
			push ( @out, "OH NOES! YOUR POP3 HAS BEEN IMAP'ed: " . $self->{errstr} );
		}
		else {
			push ( @out, "Contact successfully updated!" );
			push ( @out, $q->br );
		}
	}
	else {
		if ( $vars->{co} && (my $current = $self->lookup_contact_by_seq( $vars->{co} ) ) ) {
			my %salutations = (
				1 => 'Mr.',
				2 => 'Ms.',
				3 => 'Mrs.',
				4 => 'Dr.',
			);
			my %pcont = (
				1 => 'E-Mail',
				2 => 'Phone',
				3 => 'Postal Mail',
			);
			my $clist = $self->view_all_companies;
			my %companies;
			foreach my $company ( @{ $clist } ) {
				$companies{$company->{seq}} = $company->{name}
			}
			push ( @out,  $q->start_form );
			push ( @out,  $q->hidden({
				-name => 'act',
				-value => '0011',
				-override => 1,
			}) );
			push ( @out,  $q->hidden({
				-name => 'co',
				-value => $vars->{co},
				-override => 1,
			}) );
			push ( @out,  '<label class="sleek-bold" for="prefix">Salutation:</label>' );
			push ( @out,  $q->popup_menu(
				-name => 'prefix',
				-values => \%salutations,
				-labels => \%salutations,
				-class => 'sleek',
				-selected => $current->{prefix},
				-default => $current->{prefix},
				-override => 1,
			) );
			push ( @out,  $q->br );
			push ( @out,  '<label class="sleek-bold" for="fname">First Name:</label>' );
			push ( @out,  $q->textfield(
				-name => 'fname',
				-id => 'fname',
				-class => 'sleek',
				-maxlength => 16,
				-default => $current->{fname},
				-value => $current->{fname},
			) );
			push ( @out,  $q->br );
			push ( @out,  '<label class="sleek-bold" for="lname">Last Name:</label>' );
			push ( @out,  $q->textfield(
				-name => 'lname',
				-id => 'lname',
				-class => 'sleek',
				-maxlength => 16,
				-default => $current->{lname},
				-value => $current->{lname},
			) );
			push ( @out,  $q->br );
			push ( @out,  '<label class="sleek-bold" for="email">E-Mail:</label>' );
			push ( @out,  $q->textfield(
				-name => 'email',
				-id => 'email',
				-class => 'sleek',
				-maxlength => 48,
				-default => $current->{email},
				-value => $current->{email},
			) );
			push ( @out,  $q->br );
			push ( @out,  $q->hr({ -class => 'mini' }) );
			push ( @out,  '<label class="sleek-bold" for="company">Company:</label>' );
			push ( @out,  $q->popup_menu(
				-name => 'company',
				-values => \%companies,
				-labels => \%companies,
				-class => 'sleek-large',
				-selected => $current->{company},
				-default => $current->{company},
				-override => 1,
			) );
			push ( @out,  $q->br );
			push ( @out,  '<label class="sleek" for="url">URL:</label>' );
			push ( @out,  $q->textfield(
				-name => 'url',
				-id => 'url',
				-class => 'sleek',
				-maxlength => 255,
				-value => $current->{url},
				-default => $current->{url},
				-override => 1,
			) );
			push ( @out,  $q->br );
			push ( @out,  '<label class="sleek-bold" for="phone">Phone:</label>' );
			push ( @out,  $q->textfield(
				-name => 'phone',
				-id => 'phone',
				-class => 'sleek',
				-maxlength => 16,
				-value => $current->{phone},
				-default => $current->{phone},
				-override => 1,
			) );
			push ( @out,  $q->br );
			push ( @out,  '<label class="sleek" for="ext">Extension:</label>' );
			push ( @out,  $q->textfield(
				-name => 'ext',
				-id => 'ext',
				-class => 'sleek-small',
				-maxlength => 6,
				-default => $current->{ext},
				-value => $current->{ext},
				-override => 1,
			) );
			push ( @out,  $q->br );
			push ( @out,  '<label class="sleek" for="cell">Cell:</label>' );
			push ( @out,  $q->textfield(
				-name => 'cell',
				-id => 'cell',
				-class => 'sleek',
				-maxlength => 16,
				-default => $current->{cell},
				-value => $current->{cell},
				-override => 1,
			) );
			push ( @out,  $q->br );
			push ( @out,  '<label class="sleek" for="fax">Fax:</label>' );
			push ( @out,  $q->textfield(
				-name => 'fax',
				-id => 'fax',
				-class => 'sleek',
				-maxlength => 16,
				-default => $current->{fax},
				-value => $current->{fax},
				-override => 1,
			) );
			push ( @out,  $q->br );
			push ( @out,  '<label class="sleek-bold" for="address">Street Address:</label>' );
			push ( @out,  $q->textfield(
				-name => 'address',
				-id => 'address',
				-class => 'sleek',
				-maxlength => 48,
				-default => $current->{address},
				-value => $current->{address},
				-override => 1,
			) );
			push ( @out,  $q->br );
			push ( @out,  '<label class="sleek" for="suite">Suite:</label>' );
			push ( @out,  $q->textfield(
				-name => 'suite',
				-id => 'suite',
				-class => 'sleek-small',
				-maxlength => 12,
				-default => $current->{suite},
				-value => $current->{suite},
				-override => 1,
			) );
			push ( @out,  $q->br );
			push ( @out,  '<label class="sleek-bold" for="zip">Zipcode:</label>' );
			push ( @out,  $q->textfield(
				-name => 'zip',
				-id => 'zip',
				-class => 'sleek-small',
				-maxlength => 5,
				-default => $current->{zipcode},
				-value => $current->{zipcode},
				-override => 1,
			) );
			push ( @out,  $q->br );
			push ( @out,  $q->hr({ -class => 'mini' }) );
			push ( @out,  '<label class="sleek-bold" for="prefer">Prefer Contact Via:</label>' );
			push ( @out,  $q->popup_menu(
				-name => 'prefer',
				-values => \%pcont,
				-labels => \%pcont,
				-class => 'sleek',
				-selected => $current->{prefer},
				-default => $current->{prefer},
				-override => 1,
			) );
			push ( @out,  $q->br );
			push ( @out,  $q->hr({ -class => 'mini' }) );
			push ( @out,  $q->start_div({ -class => 'sleek-button' }) );
			push ( @out,  $q->submit({
				-class => 'sleek-button',
				-value => 'Change!',
				-id => 'submit',
				-name => 'submit',
			}) );
			push ( @out,  $q->end_div );
			push ( @out,  $q->end_form );
		}
		else {
			push ( @out,  'Fatal error: No shizzle to go with that w00t' );
		}
	}
	push ( @out,  $q->hr({ -class => 'mini' }) );
	push ( @out,  $q->br );

	return \@out;
}

sub display_delete_contact {
	my ( $self, $dbh, $q, $vars ) = @_;

	my @out;

	if ( !$vars->{co} ) {
		push ( @out, 'Danger, danger Will Robinson!' );
	}
	else {
		if ( $self->lookup_contact_by_seq( $vars->{co} ) ) {
			if ( $self->delete_contact_by_seq( $vars->{co} ) ) {
				push ( @out, 'Successfully deleted contact' );
			}
			else {
				push ( @out, 'Failed to delete contact "' . $vars->{co} . '": ' . $self->{errstr} );
			}
		}
		else {
			push ( @out, 'Stop playin around and get to work!' );
		}
	}

	return \@out;
}

sub display_contact_notes {
	my ( $self, $dbh, $q, $vars ) = @_;

	my @out;

	push ( @out,  $q->h3( "Contact Notes" ) );
	push ( @out,  $q->hr({ -class => 'mini' }) );
	push ( @out,  $q->br );
	if ( !$vars->{co} ) {
		push ( @out, 'Danger, danger Will Robinson!' );
	}
	else {
		if ( my $notes = $self->get_contact_notes( $vars->{co} ) ) {
			my $num = $self->get_num_notes( $vars->{co} );
			push ( @out,  $q->start_div({ -align => 'center' }) );
			push ( @out,  "Found $num notes for contact" );
			push ( @out,  $q->end_div );
			my %prefixes = (
				1 => 'Mr.',
				2 => 'Ms.',
				3 => 'Mrs.',
				4 => 'Dr.',
			);
			my $contact = $self->lookup_contact_by_seq( $vars->{co} );
			push ( @out,  $q->start_div({ -class => 'block' }) );
			push ( @out,  $q->start_div({ -class => 'block-title' }) );
			push ( @out,  $contact->{companyName} );
			push ( @out,  $q->end_div );
			push ( @out,  $q->start_ul({ -class => 'sleek' }) );
			push ( @out,  $q->start_li . $prefixes{$contact->{prefix}} . ' ' . join( ", ", $contact->{lname}, $contact->{fname} ) . $q->end_li );
			push ( @out,  $q->start_li . $contact->{url} . $q->end_li ) if $contact->{url};
			push ( @out,  $q->br );
			push ( @out,  $q->start_li . $contact->{address} . $q->end_li );
			push ( @out,  $q->start_li . $contact->{suite} . $q->end_li ) if $contact->{suite};
			push ( @out,  $q->start_li . join ( ", ", $contact->{city}, $contact->{state}, $contact->{zip} ) . $q->end_li );
			push ( @out,  $q->br );
			push ( @out,  $q->start_li . 'em: ' . $contact->{email} . $q->end_li );
			push ( @out,  $q->start_li . 'ph: ' . $contact->{phone} );
			push ( @out,  " x " . $contact->{ext} ) if $contact->{ext};
			push ( @out,  $q->end_li );
			push ( @out,  $q->start_li . 'ce: ' . $contact->{cell} . $q->end_li . $q->br ) if $contact->{cell};
			push ( @out,  $q->start_li . 'fx: ' . $contact->{fax} . $q->end_li ) if $contact->{fax};
			push ( @out,  $q->start_div({ -align => 'center' }) );
			push ( @out,  '[ ' . $q->a({ -href => $q->url . '?act=0110;co=' . $contact->{seq} }, "add note" ) . ' ]' );
			push ( @out,  '[ ' . $q->a({ -href => $q->url . '?act=0011;co=' . $contact->{seq} }, "edit" ) . ' ]' );
			push ( @out,  '[ ' . $q->a({ -href => 'mailto:' . $contact->{email} }, "e-mail" ) . ' ]' );
			push ( @out,  $q->end_div );
			push ( @out,  $q->end_div );
			push ( @out,  $q->br );
			my %months = (
				'01' => 'January',
				'02' => 'February',
				'03' => 'March',
				'04' => 'April',
				'05' => 'May',
				'06' => 'June',
				'07' => 'July',
				'08' => 'August',
				'09' => 'September',
				'10' => 'October',
				'11' => 'November',
				'12' => 'December',
			);
			foreach my $note ( @{ $notes } ) {
				my ( $year,$mo,$day,$hour,$min,$sec ) = unpack( "A4A2A2A2A2A2", $note->{ts} );
				push ( @out,  $q->start_div({ -class => 'block' }) );
				push ( @out,  $q->start_div({ -class => 'block-title' }) );
				push ( @out,  sprintf("%s %s, %s - %s:%s:%s", $months{$mo}, $day, $year, $hour, $min, $sec ) );
				push ( @out,  $q->end_div );
				push ( @out,  $q->start_ul({ -class => 'sleek' }) );
				push ( @out,  $q->br );
				push ( @out,  $note->{note} );
				push ( @out,  $q->br, $q->br );
				push ( @out,  $q->start_div({ -align => 'center' }) );
				push ( @out,  '[ ' .  $q->a({ -href => $q->url . '?act=0111;ni=' . $note->{seq} }, 'delete' ) . ' ]' );
				push ( @out,  $q->end_div );
				push ( @out,  $q->end_ul );
				push ( @out,  $q->end_div );
				push ( @out,  $q->br );
			}
		}
	}

	return \@out;
}

#
## End of high-level functions

1;
