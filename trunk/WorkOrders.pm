#!/usr/bin/perl

package WorkOrders;

use warnings;
use strict;
use Common;
use Contacts;

my $contact = Contacts->new;

sub new {
	my $class = shift;
	my $self = { };
	bless $self, $class;
	$self->{common} = new Common or do {
		print STDERR "Failed to create Common.pm reference";
		return;
	};

	$self->{dispatch} = (
		'00000000'	=>	\&WorkOrders::show_open_wo,
		'00010000'	=>	\&WorkOrders::find_wo,
		'00100010'	=>	\&WorkOrders::edit_wo,
		'00100000'	=>	\&WorkOrders::create_wo,
		'00100001'	=>	\&WorkOrders::store_wo,
		'00100011'	=>	\&WorkOrders::invoice_wo,
	);

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

sub find_wo {
	my ( $q, $vars, $wo ) = @_;
	my @out;

	push ( @out, $q->h3( 'Search Work Orders' ) );
	push ( @out, $q->hr({ -class => 'mini' }) );
	push ( @out, $q->br );

	return @out;
}

sub edit_wo {
	my ( $q, $vars, $wo ) = @_;
	my @out;

	if ( !$vars->{won} ) {
		push ( @out, $q->h2('No workorder selected') );
		return @out;
	}

	# Fetch workorder's current info
	my $cwo = $wo->lookup_wo_by_seq( $vars->{won} ) || do {
		push ( @out, $q->h2('Failed to lookup workorder') );
		return @out;
	};

	# Have edits already been made and ready for commit?
	if ( $vars->{emp1} && $vars->{desc1} && $vars->{hours1} && $vars->{phase1} ) {
		# Yep, we have at least one good line item
		for my $i (1..5) {
			# Skip line items that are blank or partial
			next unless $vars->{"emp" . $i} && $vars->{"desc" . $i} && $vars->{"hours" . $i} && $vars->{"phase" . $i};
			my %entity = (
				'won' => $vars->{won},
				'employee' => $vars->{"emp$i"},
				'descr' => $vars->{"desc$i"},
				'hours' => $vars->{"hours$i"},
				'phase' => $vars->{"phase$i"},
			);
			if ( $vars->{"liseq" . $i} ) {
				# Line item is an edit, not an add
				$entity{liseq} = $vars->{"liseq" . $i};
				if ( $wo->change_li( \%entity ) ) {
					push ( @out, 'Changed line item: ' . $i . $q->br );
				}
				else {
					push ( @out, 'Failed to change line item: ' . $i . $q->br );
				}
			}
			else {
				# Cool, add a new line item to workorder
				if ( $wo->add_li_to_wo( \%entity ) ) {
					push ( @out, 'Added line item: ' . $i . $q->br );
				}
				else {
					push ( @out, 'Failed to add line item: ' . $i );
				}
			}
		}
	}

	# Lookup company info related to workorder
	my $company = $contact->lookup_company_by_seq( $cwo->{company} );

	# Get all line items currently associated with workorder
	my $li = $wo->get_li_by_wo_seq( $vars->{won} );

	# Get hashref of all employees
	my $employees = $wo->get_all_employees();

	# Fetch hashref of all phases
	my $phases = $wo->get_all_phases();

	$employees->{0} = '-------------------';
	$phases->{0} = '---------';
	push ( @out, $q->start_div({ -class => 'block' }) );
	push ( @out, $q->start_div({ -class => 'block-title' }) );
	push ( @out, $q->b( 'WO #: ' . $cwo->{ref} ) );
	push ( @out, $q->end_div );
	push ( @out, $q->start_ul({ -class => 'sleek' }) );
	push ( @out, $q->start_li, $q->b( $company->{name} ), $q->end_li );
	push ( @out, $q->start_li, 'Phone: ', $company->{phone}, $q->end_li );
	push ( @out, $q->start_li, 'Fax: ', $company->{fax}, $q->end_li ) if $company->{fax};
	push ( @out, $q->start_li, $company->{address}, $q->end_li );
	push ( @out, $q->start_li, $company->{address2}, $q->end_li ) if $company->{address2};
	push ( @out, $q->start_li, $company->{city}, ', ', $company->{state}, ', ', $company->{zip}, $q->end_li );
	push ( @out, $q->start_li, $q->a({ -target => '_new', -href => $company->{url} }, $company->{url} ), $q->end_li ) if $company->{url};
	push ( @out, $q->end_ul );
	push ( @out, $q->end_div );

	push ( @out, $q->br );

	push ( @out, $q->start_div({ -class => 'block' }) );
	push ( @out, $q->start_div({ -class => 'block-title' }) );
	push ( @out, 'Line Items' );
	push ( @out, $q->end_div );
	push ( @out, $q->start_form );
	push ( @out, $q->hidden(
		-name		=>	'won',
		-value		=>	$vars->{seq},
		-override	=>	1,
	) );
	push ( @out, $q->hidden(
		-name		=>	'company',
		-value		=>	$vars->{company},
		-override	=>	1,
	) );

	push ( @out, $q->hidden(
		-name		=>	'act',
		-value		=>	'00100001',
		-override	=>	1,
	) );

	push ( @out, $q->start_div({ -class => 'sleek' }) );
	push ( @out, $q->start_table({
		-width		=>	'100%',
		-cellpadding	=>	0,
		-cellspacing	=>	0,
	}) );
	push ( @out, $q->start_Tr );
	push ( @out, $q->start_td, '#' . $q->end_td );
	push ( @out, $q->start_td, 'Employee', $q->end_td );
	push ( @out, $q->start_td, 'Description', $q->end_td );
	push ( @out, $q->start_td, 'Hours', $q->end_td );
	push ( @out, $q->start_td, 'Phase', $q->end_td );
	push ( @out, $q->end_Tr );

	for (my $i=1;$i<=5;$i++) {
		my $bgc = '#d5d5d5';
		$bgc = '#b0b0b0' if ( $i % 2 );
		push ( @out, $q->start_Tr({ -bgcolor => $bgc }) );
		push ( @out, $q->start_td, $i . $q->end_td );
		push ( @out, $q->hidden(
			-name		=>	'liseq' . $i,
			-value		=>	$li->[$i-1]->{seq},
			-override	=>	1,
		) );
		push ( @out, $q->start_td, $q->popup_menu(
			-name		=>	"emp$i",
			-values		=>	$employees,
			-labels		=>	$employees,
			-default	=>	$li->[$i-1]->{employee} || 0,
			-class		=>	'sleek-mid',
		), $q->end_td );
		push ( @out, $q->start_td, $q->textfield(
			-name		=>	"desc$i",
			-maxlength	=>	255,
			-class		=>	'sleek',
			-default	=>	$li->[$i-1]->{descr} || undef,
		), $q->end_td );
		push ( @out, $q->start_td, $q->textfield(
			-name		=>	"hours$i",
			-maxlength	=>	8,
			-class		=>	'sleek-micro',
			-default	=>	$li->[$i-1]->{hours} || undef,
		), $q->end_td );
		push ( @out, $q->start_td, $q->popup_menu(
			-name		=>	"phase$i",
			-values		=>	[ sort { $a <=> $b } keys %{$phases} ],
			-labels		=>	$phases,
			-default	=>	$li->[$i-1]->{phaseseq} || 0,
			-class		=>	'sleek',
		), $q->end_td );
		push ( @out, $q->end_Tr );
	}
	push ( @out, $q->end_table );
	push ( @out, $q->end_div, $q->end_div );
	push ( @out, $q->hr({ -class => 'mini' }) );
	push ( @out, $q->start_div({ -class => 'sleek-button' }), $q->reset( -value => 'Reset', class => 'sleek-button' ), $q->submit( -value => 'Modify', class => 'sleek-button' ), $q->end_div );
	push ( @out, $q->end_form );
	push ( @out, $q->br );
	return @out;
}

sub create_wo {
	my ( $q, $vars, $wo ) = @_;
	my @out;

	push ( @out, $q->h3( 'Create Work Order' ) );
	push ( @out, $q->hr({ -class => 'mini' }) );

	if ( $vars->{won} && $vars->{company} ) {
		if ( my $company = $contact->lookup_company_by_seq( $vars->{company} ) ) {

			if ( $wo->lookup_wo_by_seq( $vars->{won} ) ) {
				# FIXME!
				push ( @out, $q->h4( 'WO already exists!' ) );
			}
			else {
				my %entity = (
					'company' => $vars->{company},
					'won' => $vars->{won},
				);
				my $seq = $wo->add_wo( \%entity ); 
				my $employees = $wo->get_all_employees();
				my $phases = $wo->get_all_phases();
				$employees->{0} = '-------------------';
				$phases->{0} = '---------';
				push ( @out, $q->start_div({ -class => 'block' }) );
				push ( @out, $q->start_div({ -class => 'block-title' }) );
				push ( @out, $q->b( 'WO #: ' . $vars->{won} ) );
				push ( @out, $q->end_div );
				push ( @out, $q->start_ul({ -class => 'sleek' }) );
				push ( @out, $q->start_li, $q->b( $company->{name} ), $q->end_li );
				push ( @out, $q->start_li, 'Phone: ', $company->{phone}, $q->end_li );
				push ( @out, $q->start_li, 'Fax: ', $company->{fax}, $q->end_li ) if $company->{fax};
				push ( @out, $q->start_li, $company->{address}, $q->end_li );
				push ( @out, $q->start_li, $company->{address2}, $q->end_li ) if $company->{address2};
				push ( @out, $q->start_li, $company->{city}, ', ', $company->{state}, ', ', $company->{zip}, $q->end_li );
				push ( @out, $q->start_li, $q->a({ -target => '_new', -href => $company->{url} }, $company->{url} ), $q->end_li ) if $company->{url};
				push ( @out, $q->end_ul );
				push ( @out, $q->end_div );

				push ( @out, $q->br );

				push ( @out, $q->start_div({ -class => 'block' }) );
				push ( @out, $q->start_div({ -class => 'block-title' }) );
				push ( @out, 'Line Items' );
				push ( @out, $q->end_div );
				push ( @out, $q->start_form );
				push ( @out, $q->hidden(
					-name		=>	'won',
					-value		=>	$seq,
					-override	=>	1,
				) );
				push ( @out, $q->hidden(
					-name		=>	'company',
					-value		=>	$vars->{company},
					-override	=>	1,
				) );

				push ( @out, $q->hidden(
					-name		=>	'act',
					-value		=>	'00100001',
					-override	=>	1,
				) );
				push ( @out, $q->start_div({ -class => 'sleek' }) );
				push ( @out, $q->start_table({
					-width		=>	'100%',
					-cellpadding	=>	0,
					-cellspacing	=>	0,
				}) );

				push ( @out, $q->start_Tr );
				push ( @out, $q->start_td, '#' . $q->end_td );
				push ( @out, $q->start_td, 'Employee', $q->end_td );
				push ( @out, $q->start_td, 'Description', $q->end_td );
				push ( @out, $q->start_td, 'Hours', $q->end_td );
				push ( @out, $q->start_td, 'Phase', $q->end_td );
				push ( @out, $q->end_Tr );

				for (my $i=1;$i<=5;$i++) {
					my $bgc = '#d5d5d5';
					$bgc = '#b0b0b0' if ( $i % 2 );
					push ( @out, $q->start_Tr({ -bgcolor => $bgc }) );
					push ( @out, $q->start_td, $i . $q->end_td );
					push ( @out, $q->start_td, $q->popup_menu(
						-name		=>	"emp$i",
						-values		=>	$employees,
						-labels		=>	$employees,
						-default	=>	0,
						-class		=>	'sleek-mid',
						-override	=>	1,
					), $q->end_td );
					push ( @out, $q->start_td, $q->textfield(
						-name		=>	"desc$i",
						-maxlength	=>	255,
						-class		=>	'sleek',
					), $q->end_td );
					push ( @out, $q->start_td, $q->textfield(
						-name		=>	"hours$i",
						-maxlength	=>	8,
						-class		=>	'sleek-micro',
					), $q->end_td );
					push ( @out, $q->start_td, $q->popup_menu(
						-name		=>	"phase$i",
						-values		=>	[ sort { $a <=> $b } keys %{$phases} ],
						-labels		=>	$phases,
						-default	=>	0,
						-class		=>	'sleek',
						-override	=>	1,
					), $q->end_td );
					push ( @out, $q->end_Tr );
				}
				push ( @out, $q->end_table );
				push ( @out, $q->end_div, $q->end_div );
				push ( @out, $q->hr({ -class => 'mini' }) );
				push ( @out, $q->start_div({ -class => 'sleek-button' }), $q->submit( -value => 'Create', class => 'sleek-button' ), $q->end_div );
				push ( @out, $q->end_form );
				push ( @out, $q->br );
			}
		}
		else {
			push ( @out, $q->h4( 'Invalid company attempted!' ) );
		}
	}
	else {
		my $companies = $wo->get_all_companies();
		push ( @out, $q->start_form );
		push ( @out, $q->hidden(
			-name		=>	'act',
			-value		=>	'00100000',
			-override	=>	1,
		) );
		push ( @out, '<label class="sleek-bold" for="won">WO Number:</label>' );
		push ( @out, $q->textfield(
			-name		=>	'won',
			-id		=>	'won',
			-class		=>	'sleek-small',
			-maxlength	=>	8,
		) );
		push ( @out, $q->br );
		push ( @out, '<label class="sleek-bold" for="company">Company:</label>' );
		push ( @out, $q->popup_menu(
			-name		=>	'company',
			-id		=>	'company',
			-values		=>	$companies,
			-labels		=>	$companies,
			-class		=>	'sleek-large',
		) );
		push ( @out, $q->br );
		push ( @out, $q->hr({ -class => 'mini' }) );
		push ( @out, $q->start_div({ -class => 'sleek-button' }) );
		push ( @out, $q->submit({
			-class		=>	'sleek-button',
			-value		=>	'Create!',
			-id		=>	'submit',
			-name		=>	'submit',
		}) );
		push ( @out, $q->end_div );
		push ( @out, $q->end_form );
	}
	return @out;
}

sub store_wo {
	my ( $q, $vars, $wo ) = @_;
	my @out;

	if ( $vars->{emp1} && $vars->{desc1} && $vars->{hours1} && $vars->{phase1} ) {
		# Cool, we got at least 1 complete line item
		for my $i (1..5) {
			next unless $vars->{"emp" . $i} && $vars->{"desc" . $i} && $vars->{"hours" . $i} && $vars->{"phase" . $i};
			my %entity = (
				'won' => $vars->{won},
				'employee' => $vars->{"emp$i"},
				'descr' => $vars->{"desc$i"},
				'hours' => $vars->{"hours$i"},
				'phase' => $vars->{"phase$i"},
			);
			if ( $wo->add_li_to_wo( \%entity ) ) {
				push ( @out, 'Added line item: ' . $i . $q->br );
			}
			else {
				push ( @out, 'Failed to add line item: ' . $i );
			}
		} 
	}
	else {
		# Doh! Someone train this monkey!
		push ( @out, $q->h3({ -style => 'color:red' }, "Incomplete data entered, go back and try again") );
	}

	return @out;
}

sub invoice_wo {
	my ( $q, $vars, $wo ) = @_;
	my @out;

	return $q->h3({ -style => 'color:red' }, 'No work order specified!' ) unless $vars->{won};

	if ( !$vars->{wotoinv} || $vars->{wotoinv} == 0 ) {
		# Stage 1, prompt for invoice num
		if ( my $ticket = $wo->lookup_wo_by_seq( $vars->{won} ) ) {
			# Cool, WO exists
			if ( $ticket->{invoice} && $ticket->{invoice} != 0 ) {
				# Doh! Already invoiced!
				return $q->h3({ -style => 'color:red' }, 'Work order has already been billed on invoice: ' . $ticket->{invoice} );
			}
			else {
				# Should be cool to attach to invoice
				my $invoices = $wo->get_all_open_inv;
				push ( @out, $q->start_form );
				push ( @out, $q->hidden(
					-name		=> 'won',
					-value		=> $vars->{won},
					-override	=> 1,
				) );
				push ( @out, $q->start_div, 'Attaching WO "' . $ticket->{ref} . '" to Invoice', $q->end_div );
				push ( @out, $q->br );
				push ( @out, $q->start_div, 'Invoice: ' . $q->popup_menu(
					-name		=> 'wotoinv',
					-values		=> $invoices,
					-labels		=> $invoices,
					-default	=> 0,
				) . $q->end_div );
				push ( @out, $q->br );
				push ( @out, $q->submit(
					-name		=> 'submit',
					-value		=> 'Invoice It!',
				) );
				push ( @out, $q->end_form );
			}
		}
		else {
			# Invalid WO
			return $q->h3({ -style => 'color:red' }, 'Invalid work order specified!' );
		}
	}
	else {
		# Stage 2, update DB
	}

	return @out;
}

sub show_open_wo {
	my ( $q, $vars, $wo ) = @_;
	my @out;

	push ( @out, $q->h3( 'All Open Work Orders' ) );
	push ( @out, $q->hr({ -class => 'mini' }) );
	push ( @out, $q->br );
	my $open = $wo->get_all_open_wo();
	my $tc = 0;
	my $out_hours;
	my $out_cost;
	for my $ticket ( @{ $open } ) {
		$tc++;
		my $company = $contact->lookup_company_by_seq( $ticket->{company} );
		push ( @out, $q->start_div({ -class => 'block' }) );
		push ( @out, $q->div({ -class => 'block-title' }, 'WO#: '.$ticket->{ref}) );
		push ( @out, $q->start_div({ -class => 'sleek' }) );
		push ( @out, $q->start_b . 'Company: ' . $q->end_b . $company->{name} . $q->br . $q->br );
		push ( @out, $q->start_div({ -align => 'center' }) );
		push ( @out, $q->start_table({
			-border		=>	0,
			-cellpadding	=>	1,
			-cellspacing	=>	1,
			-width		=>	'90%',
			-align		=>	'center',
		}) );
		push ( @out, $q->start_Tr({ -bgcolor => '#dadada' }) );
		push ( @out, $q->start_td, $q->start_b, 'Date:', $q->end_b, $q->end_td );
		push ( @out, $q->start_td, $q->start_b, 'Employee:', $q->end_b, $q->end_td );
		push ( @out, $q->start_td, $q->start_b, 'Description:', $q->end_b, $q->end_td );
		push ( @out, $q->start_td, $q->start_b, 'Phase:', $q->end_b, $q->end_td );
		push ( @out, $q->start_td, $q->start_b, 'Hours:', $q->end_b, $q->end_td );
		push ( @out, $q->start_td, $q->start_b, 'Cost:', $q->end_b, $q->end_td );
		push ( @out, $q->end_Tr );
		my $ln = 0;
		my ( $tot_hours, $tot_cost );
		my $line_items = $wo->get_li_by_wo_seq( $ticket->{seq} );
		for my $li ( @{ $line_items } ) {
			$ln++;
			my $bgc = '#dadada';
			$bgc = '#cdcdcd' if $ln % 2 == 0;
			my ( $year, $mo, $mday, $hour, $min, $sec ) = unpack( "A4A2A2A2A2A2", $li->{ts} );
			$year -= 1900;
			$mo--;
			my $tl = timelocal( $sec,$min,$hour,$mday,$mo,$year );
			my $date = strftime( "%a., %b. %e, %Y", localtime( $tl ) );
			$tot_hours += $li->{hours};
			$tot_cost += $li->{cost};
			push ( @out, $q->start_Tr({ -bgcolor => $bgc }) );
			push ( @out, $q->start_td, $date, $q->end_td );
			push ( @out, $q->start_td, $li->{employee}, $q->end_td );
			push ( @out, $q->start_td, $li->{descr}, $q->end_td );
			push ( @out, $q->start_td, $li->{phase}, $q->end_td );
			push ( @out, $q->start_td, commify( $li->{hours} ), $q->end_td );
			push ( @out, $q->start_td, commify( $li->{cost} ), $q->end_td );
			push ( @out, $q->end_Tr );
		}
		push ( @out, $q->start_Tr );
		push ( @out, $q->start_td({ -colspan => 4 }) . 'Totals:' . $q->end_td );
		push ( @out, $q->start_td, $q->start_b, commify( sprintf( "%.2f", $tot_hours ) ), $q->end_b, $q->end_td );
		push ( @out, $q->start_td, $q->start_b, '$' . commify( sprintf( "%.2f", $tot_cost ) ), $q->end_b, $q->end_td );
		push ( @out, $q->end_Tr );
		push ( @out, $q->end_table );
		push ( @out, $q->end_div );
		push ( @out, $q->br );
		push ( @out, $q->start_div({ -align => 'center' }) );
		push ( @out, '[ ' . $q->a({ -href => $q->url . '?act=00100010;won=' . $ticket->{seq} }, "edit" ) . ' ]' );
		push ( @out, '[ ' . $q->a({ -href => $q->url . '?act=00100011;won=' . $ticket->{seq} }, "invoice" ) . ' ]' );
		push ( @out, $q->end_div );
		push ( @out, $q->br );
		push ( @out, $q->end_div );
		push ( @out, $q->end_div );
		push ( @out, $q->br );
		$out_cost += $tot_cost;
		$out_hours += $tot_hours;
	}
	push ( @out, $q->start_div({ -align => 'center' }) );
	push ( @out, 'Grand total outstanding:' );
	push ( @out, $q->end_div );
	push ( @out, $q->start_div({ -align => 'center' }) );
	push ( @out, 'Hours: <b>' . commify( sprintf( "%.2f", $out_hours ) ) . '</b> -- Cost: <b>$' . commify( sprintf( "%.2f", $out_cost ) ) . '</b>' );
	push ( @out, $q->end_div );
	if ( $tc < 1 ) {
		push ( @out, 'There are currently no open work orders' );
	}

	return @out;
}

1;
