#!/usr/bin/perl

use warnings;
use strict;
use Contacts;
use WorkOrders;
use WWW::CMS;
use POSIX qw( strftime );

my $c = Contacts->new();
my $wo = WorkOrders->new();
my $q = $c->{common}->{query};
my $vars = $c->{common}->{vars};
my $me = $q->url();
my $cms = WWW::CMS->new({
	TemplateBase	=>	$c->{common}->{conf}->{TemplateBase},
	Module		=>	$c->{common}->{conf}->{Module}
});

print $q->header;
$cms->{PageName} = 'Contact Management';
if ( $vars->{act} ) {
	elsif ( $vars->{act} =~ /^0110$/ ) {
		# Insert note on contact
		push ( @{ $cms->{content} },  $q->h3( "Contact Notes" ) );
		push ( @{ $cms->{content} },  $q->hr({ -class => 'mini' }) );
		push ( @{ $cms->{content} },  $q->br );
		if ( !$vars->{co} ) {
			push ( @{ $cms->{content} }, 'Danger, danger Will Robinson!' );
		}
		else {
			if ( !$vars->{note} ) {
				my %prefixes = (
					1 => 'Mr.',
					2 => 'Ms.',
					3 => 'Mrs.',
					4 => 'Dr.',
				);
				my $contact = $c->lookup_contact_by_seq( $vars->{co} );
				push ( @{ $cms->{content} },  $q->start_div({ -class => 'block' }) );
				push ( @{ $cms->{content} },  $q->start_div({ -class => 'block-title' }) );
				push ( @{ $cms->{content} },  $contact->{companyName} );
				push ( @{ $cms->{content} },  $q->end_div );
				push ( @{ $cms->{content} },  $q->start_ul({ -class => 'sleek' }) );
				push ( @{ $cms->{content} },  $q->start_li . $prefixes{$contact->{prefix}} . ' ' . join( ", ", $contact->{lname}, $contact->{fname} ) . $q->end_li );
				push ( @{ $cms->{content} },  $q->start_li . $contact->{url} . $q->end_li ) if $contact->{url};
				push ( @{ $cms->{content} },  $q->br );
				push ( @{ $cms->{content} },  $q->start_li . $contact->{address} . $q->end_li );
				push ( @{ $cms->{content} },  $q->start_li . $contact->{suite} . $q->end_li ) if $contact->{suite};
				push ( @{ $cms->{content} },  $q->start_li . join ( ", ", $contact->{city}, $contact->{state}, $contact->{zip} ) . $q->end_li );
				push ( @{ $cms->{content} },  $q->br );
				push ( @{ $cms->{content} },  $q->start_li . 'em: ' . $contact->{email} . $q->end_li );
				push ( @{ $cms->{content} },  $q->start_li . 'ph: ' . $contact->{phone} );
				push ( @{ $cms->{content} },  " x " . $contact->{ext} ) if $contact->{ext};
				push ( @{ $cms->{content} },  $q->end_li );
				push ( @{ $cms->{content} },  $q->start_li . 'ce: ' . $contact->{cell} . $q->end_li . $q->br ) if $contact->{cell};
				push ( @{ $cms->{content} },  $q->start_li . 'fx: ' . $contact->{fax} . $q->end_li ) if $contact->{fax};
				push ( @{ $cms->{content} },  $q->start_div({ -align => 'center' }) );
				push ( @{ $cms->{content} },  '[ ' . $q->a({ -href => $q->url . '?act=0110;co=' . $contact->{seq} }, "add note" ) . ' ]' );
				push ( @{ $cms->{content} },  '[ ' . $q->a({ -href => $q->url . '?act=0011;co=' . $contact->{seq} }, "edit" ) . ' ]' );
				push ( @{ $cms->{content} },  '[ ' . $q->a({ -href => 'mailto:' . $contact->{email} }, "e-mail" ) . ' ]' );
				push ( @{ $cms->{content} },  $q->end_div );
				push ( @{ $cms->{content} },  $q->end_div );
				push ( @{ $cms->{content} },  $q->br );

				push ( @{ $cms->{content} },  $q->start_div({ -class => 'block' }) );			push ( @{ $cms->{content} },  $q->start_div({ -class => 'block-title' }) );
				push ( @{ $cms->{content} },  'Note' );
				push ( @{ $cms->{content} },  $q->end_div );
				push ( @{ $cms->{content} },  $q->br );
				push ( @{ $cms->{content} },  $q->start_form );
				push ( @{ $cms->{content} },  $q->hidden(
					-name => 'co',
					-default => $vars->{co},
					-override => 1,
				) );
				push ( @{ $cms->{content} },  $q->hidden(
					-name => 'act',
					-default => '0110',
					-override => 1,
				) );
				push ( @{ $cms->{content} },  $q->textarea(
					-name => 'note',
					-class => 'sleek',
					-rows => 5,
					-columns => 40,
				) );
				push ( @{ $cms->{content} },  $q->start_div({ -class => 'sleek-button' }) );
				push ( @{ $cms->{content} },  $q->submit(
					-class => 'sleek-button',
					-value => 'Insert',
				) );
				push ( @{ $cms->{content} },  $q->end_div );
				push ( @{ $cms->{content} },  $q->end_form );
				push ( @{ $cms->{content} },  $q->end_div );
				push ( @{ $cms->{content} },  $q->br );
			}
			else {
				if ( $c->insert_contact_notes( $vars->{co}, $vars->{note} ) ) {
					push ( @{ $cms->{content} },  'Successfully appended contact note!' );
				}
				else {
					push ( @{ $cms->{content} },  'Error: Failed to insert note for contact: ', $c->{errstr} );
				}
			}
		}
	}
	elsif ( $vars->{act} =~ /^0111$/ ) {
		if ( !$vars->{ni} ) {
			push ( @{ $cms->{content} }, 'Danger, danger Will Robinson!' );
		}
		else {
			if ( $c->lookup_note_by_seq( $vars->{ni} ) ) {
				if ( $c->delete_note_by_seq( $vars->{ni} ) ) {
					push ( @{ $cms->{content} }, 'Successfully deleted contact note ID: "' . $vars->{ni} . '"' );
				}
				else {
					push ( @{ $cms->{content} }, 'Failed to delete contact note ID: "' . $vars->{co} . '": ' . $c->{errstr} );
				}
			}
			else {
				push ( @{ $cms->{content} }, 'Stop playin around and get to work!' );
			}
		}
	}
	elsif ( $vars->{act} =~ /^1000$/ ) {
		# View all companies
		push ( @{ $cms->{content} },  $q->h3( "View all companies" ) );
		push ( @{ $cms->{content} },  $q->hr({ -class => 'mini'}) );
		push ( @{ $cms->{content} },  $q->br );
		my $companies = $c->view_all_companies;
		my $matches = scalar( @{ $companies } );
		push ( @{ $cms->{content} },  $q->start_div({ -align => 'center' }) );
		if ( $matches < 1 ) {
			push ( @{ $cms->{content} },  "Sorry, you suck too much to have any companies" );
			push ( @{ $cms->{content} },  $q->end_div );
		}
		else {
			push ( @{ $cms->{content} },  "There is $matches company on record" ) if $matches <= 1;
			push ( @{ $cms->{content} },  "There are " . commie( $matches ) . " companies on record" ) if $matches > 1;
			push ( @{ $cms->{content} },  $q->end_div );
			push ( @{ $cms->{content} },  $q->br );
			my $count;
			foreach my $company ( @{ $companies } ) {
				$count++;
				push ( @{ $cms->{content} },  $q->start_div({ -class => 'block' }) );
				push ( @{ $cms->{content} },  $q->start_div({ -class => 'block-title' }) );
				push ( @{ $cms->{content} },  $company->{name} );
				push ( @{ $cms->{content} },  $q->end_div );
				push ( @{ $cms->{content} },  $q->start_ul({ -class => 'sleek' }) );
				push ( @{ $cms->{content} },  $q->start_li . 'url: ' . $company->{url} . $q->end_li ) if $company->{url};
				push ( @{ $cms->{content} },  $q->br );
				push ( @{ $cms->{content} },  $q->start_li . $company->{address} . $q->end_li );
				push ( @{ $cms->{content} },  $q->start_li . $company->{address2} . $q->end_li ) if $company->{address2};
				push ( @{ $cms->{content} },  $q->start_li . join ( ", ", $company->{city}, $company->{state}, $company->{zip} ) . $q->end_li );
				push ( @{ $cms->{content} },  $q->br );
				push ( @{ $cms->{content} },  $q->start_li . 'ph: ' . $company->{phone} );
				push ( @{ $cms->{content} },  $q->end_li );
				push ( @{ $cms->{content} },  $q->start_li . 'fx: ' . $company->{fax} . $q->end_li ) if $company->{fax};
				#push ( @{ $cms->{content} },  $q->br );
				push ( @{ $cms->{content} },  $q->start_div({ -align => 'center' }) );
				push ( @{ $cms->{content} },  '[ ' . $q->a({ -href => $q->url . '?act=00010000;co=' . $company->{seq} }, "delete" ) . ' ]' );
				push ( @{ $cms->{content} },  '[ ' . $q->a({ -href => $q->url . '?act=00010001;co=' . $company->{seq} }, "edit" ) . ' ]' );
				push ( @{ $cms->{content} },  '[ ' . $q->a({ -href => $company->{url} }, "website" ) . ' ]' ) if $company->{url};
				push ( @{ $cms->{content} },  $q->end_div );
				push ( @{ $cms->{content} },  $q->end_ul );
				push ( @{ $cms->{content} },  $q->end_div );
				push ( @{ $cms->{content} },  $q->br );
			}
		}
		push ( @{ $cms->{content} },  $q->hr({ -class => 'mini' }) );
		push ( @{ $cms->{content} },  $q->br );
	}
	elsif ( $vars->{act} =~ /^00010000$/ ) {
		# Delete company
		if ( !$vars->{co} ) {
			push ( @{ $cms->{content} }, 'w00f?' );
		}
		else {
			if ( my $company = $c->lookup_company_by_seq( $vars->{co} ) ) {
				if ( $c->delete_company_by_seq( $vars->{co} ) ) {
					push ( @{ $cms->{content} }, 'Successfully deleted company: "' . $company->{name} . '"' );
				}
				else {
					push ( @{ $cms->{content} }, 'Error: ' . $c->{errstr} );
				}
			}
			else {
				push ( @{ $cms->{content} }, 'Abort, Retry, Fail?!' );
			}
		}
	}
	elsif ( $vars->{act} =~ /^00010001$/ ) {
		# Edit company
		push ( @{ $cms->{content} },  $q->h3( "Edit Company" ) );
		push ( @{ $cms->{content} },  $q->hr({ -class => 'mini' }) );
		push ( @{ $cms->{content} },  $q->br );
		if ( $vars->{name} && $vars->{address} && $vars->{phone} && $vars->{zip} && $c->lookup_company_by_seq( $vars->{co} ) ) {
			my %entity = (
				name => $vars->{name},
				url => $vars->{url},
				address => $vars->{address},
				address2 => $vars->{address2},
				zip => $vars->{zip},
				phone => $vars->{phone},
				fax => $vars->{fax},
			);
			my $ret = $c->update_company_by_seq( $vars->{co}, \%entity );
			if ( !$ret ) {
				push ( @{ $cms->{content} }, "OH NOES! YOUR POP3 HAS BEEN IMAP'ed: " . $c->{errstr} );
			}
			else {
				push ( @{ $cms->{content} }, "Company successfully updated!" );
				push ( @{ $cms->{content} }, $q->br );
			}
		}
		else {
			if ( $vars->{co} && (my $current = $c->lookup_company_by_seq( $vars->{co} ) ) ) {
				my $clist = $c->view_all_companies;
				my %companies;
				foreach my $company ( @{ $clist } ) {
					$companies{$company->{seq}} = $company->{name}
				}
				push ( @{ $cms->{content} },  $q->start_form );
				push ( @{ $cms->{content} },  $q->hidden({
					-name => 'act',
					-value => '00010001',
					-override => 1,
				}) );
				push ( @{ $cms->{content} },  $q->hidden({
					-name => 'co',
					-value => $vars->{co},
					-override => 1,
				}) );
				push ( @{ $cms->{content} },  $q->br );
				push ( @{ $cms->{content} },  '<label class="sleek-bold" for="name">Company Name:</label>' );
				push ( @{ $cms->{content} },  $q->textfield(
					-name => 'name',
					-id => 'name',
					-class => 'sleek',
					-maxlength => 48,
					-default => $current->{name},
					-value => $current->{name},
				) );
				push ( @{ $cms->{content} },  $q->br );
				push ( @{ $cms->{content} },  '<label class="sleek" for="url">URL:</label>' );
				push ( @{ $cms->{content} },  $q->textfield(
					-name => 'url',
					-id => 'url',
					-class => 'sleek',
					-maxlength => 255,
					-value => $current->{url},
					-default => $current->{url},
					-override => 1,
				) );
				push ( @{ $cms->{content} },  $q->br );
				push ( @{ $cms->{content} },  '<label class="sleek-bold" for="phone">Phone:</label>' );
				push ( @{ $cms->{content} },  $q->textfield(
					-name => 'phone',
					-id => 'phone',
					-class => 'sleek',
					-maxlength => 16,
					-value => $current->{phone},
					-default => $current->{phone},
					-override => 1,
				) );
				push ( @{ $cms->{content} },  $q->br );
				push ( @{ $cms->{content} },  '<label class="sleek" for="fax">Fax:</label>' );
				push ( @{ $cms->{content} },  $q->textfield(
					-name => 'fax',
					-id => 'fax',
					-class => 'sleek',
					-maxlength => 16,
					-default => $current->{fax},
					-value => $current->{fax},
					-override => 1,
				) );
				push ( @{ $cms->{content} },  $q->br );
				push ( @{ $cms->{content} },  '<label class="sleek-bold" for="address">Street Address:</label>' );
				push ( @{ $cms->{content} },  $q->textfield(
					-name => 'address',
					-id => 'address',
					-class => 'sleek',
					-maxlength => 48,
					-default => $current->{address},
					-value => $current->{address},
					-override => 1,
				) );
				push ( @{ $cms->{content} },  $q->br );
				push ( @{ $cms->{content} },  '<label class="sleek" for="address2">Address Line 2:</label>' );
				push ( @{ $cms->{content} },  $q->textfield(
					-name => 'address2',
					-id => 'address2',
					-class => 'sleek',
					-maxlength => 48,
					-default => $current->{address2},
					-value => $current->{address2},
					-override => 1,
				) );
				push ( @{ $cms->{content} },  $q->br );
				push ( @{ $cms->{content} },  '<label class="sleek-bold" for="zip">Zipcode:</label>' );
				push ( @{ $cms->{content} },  $q->textfield(
					-name => 'zip',
					-id => 'zip',
					-class => 'sleek-small',
					-maxlength => 5,
					-default => $current->{zip},
					-value => $current->{zip},
					-override => 1,
				) );
				push ( @{ $cms->{content} },  $q->br );
				push ( @{ $cms->{content} },  $q->hr({ -class => 'mini' }) );
				push ( @{ $cms->{content} },  $q->start_div({ -class => 'sleek-button' }) );
				push ( @{ $cms->{content} },  $q->submit({
					-class => 'sleek-button',
					-value => 'Change!',
					-id => 'submit',
					-name => 'submit',
				}) );
				push ( @{ $cms->{content} },  $q->end_div );
				push ( @{ $cms->{content} },  $q->end_form );
			}
			else {
				push ( @{ $cms->{content} },  'Fatal error: No shizzle to go with that w00t' );
			}
		}
		push ( @{ $cms->{content} },  $q->hr({ -class => 'mini' }) );
		push ( @{ $cms->{content} },  $q->br );
	}
	elsif ( $vars->{act} =~ /^1001$/ ) {
		# Find company
		push ( @{ $cms->{content} },  $q->h3( "Find Company" ) );
		push ( @{ $cms->{content} },  $q->hr({ -class => 'mini'}) );
		push ( @{ $cms->{content} },  $q->start_form );
		push ( @{ $cms->{content} },  $q->hidden(	-name		=> 'act',
								-value		=> '1001',
								-override	=> 1	) );
		push ( @{ $cms->{content} },  $q->start_div({	-align	=> 'center' }) );
		push ( @{ $cms->{content} },  $q->textfield(	-class	=> 'sleek-small',
								-name	=> 'crit',
								-value	=> ''		) );
		push ( @{ $cms->{content} },  $q->submit(	-class	=> 'sleek-button',
								-value	=> 'Find!'	) );
		push ( @{ $cms->{content} },  $q->end_div );
		push ( @{ $cms->{content} },  $q->end_form );
		if ( $vars->{crit} ) {
			my $companies = $c->find_company( $vars->{crit} );
			my $matches = scalar( @{$companies} );
			if ( $matches < 1 ) {
				push ( @{ $cms->{content} },  $q->start_div({ -align => 'center' }) );
				push ( @{ $cms->{content} },  "Found no matches for: '$vars->{crit}'" );
				push ( @{ $cms->{content} },  $q->end_div );
			}
			else {
				push ( @{ $cms->{content} },  $q->start_div({ -align => 'center' }) );
				if ( $matches > 1 ) {
					push ( @{ $cms->{content} },  "Found " . commie( $matches ) . " matches" );
				}
				else {
					push ( @{ $cms->{content} },  "Found $matches match" );
				}
				push ( @{ $cms->{content} },  " for: '$vars->{crit}'" );
				push ( @{ $cms->{content} },  $q->end_div );
				my $count;
				foreach my $company ( @{ $companies } ) {
					$count++;
					(my $companyName = $company->{name}) =~ s/($vars->{crit})/\<b\>\<u\>$1\<\/u\>\<\/b\>/gi;
					(my $address = $company->{address}) =~ s/($vars->{crit})/\<b\>\<u\>$1\<\/u\>\<\/b\>/gi;
					(my $address2 = $company->{address2}) =~ s/($vars->{crit})/\<b\>\<u\>$1\<\/u\>\<\/b\>/gi if $company->{suite};
					(my $url = $company->{url}) =~ s/($vars->{crit})/\<b\>\<u\>$1\<\/u\>\<\/b\>/gi if $company->{url};
					(my $city = $company->{city}) =~ s/($vars->{crit})/\<b\>\<u\>$1\<\/u\>\<\/b\>/gi;
					(my $zip = $company->{zip}) =~ s/($vars->{crit})/\<b\>\<u\>$1\<\/u\>\<\/b\>/gi;
					(my $phone = $company->{phone}) =~ s/($vars->{crit})/\<b\>\<u\>$1\<\/u\>\<\/b\>/gi;
					(my $fax = $company->{fax}) =~ s/($vars->{crit})/\<b\>\<u\>$1\<\/u\>\<\/b\>/gi if $company->{fax};
					push ( @{ $cms->{content} },  $q->start_div({ -class => 'block' }) );
					push ( @{ $cms->{content} },  $q->start_div({ -class => 'block-title' }) );
					push ( @{ $cms->{content} },  $companyName );
					push ( @{ $cms->{content} },  $q->end_div );
					push ( @{ $cms->{content} },  $q->start_ul({ -class => 'sleek' }) );
					push ( @{ $cms->{content} },  $q->start_li . $url . $q->end_li ) if $url;
					push ( @{ $cms->{content} },  $q->br );
					push ( @{ $cms->{content} },  $q->start_li . $address . $q->end_li );
					push ( @{ $cms->{content} },  $q->start_li . $address2 . $q->end_li ) if $address2;
					push ( @{ $cms->{content} },  $q->start_li . join ( ", ", $city, $company->{state}, $zip ) . $q->end_li );
					push ( @{ $cms->{content} },  $q->br );
					push ( @{ $cms->{content} },  $q->start_li . 'ph: ' . $phone );
					push ( @{ $cms->{content} },  $q->end_li );
					push ( @{ $cms->{content} },  $q->start_li . 'fx: ' . $fax . $q->end_li ) if $fax;
					#push ( @{ $cms->{content} },  $q->br );
					push ( @{ $cms->{content} },  $q->start_div({ -align => 'center' }) );
					push ( @{ $cms->{content} },  '[ ' . $q->a({ -href => $q->url . '?act=00010010;co=' . $company->{seq} }, "delete" ) . ' ]' );
					push ( @{ $cms->{content} },  '[ ' . $q->a({ -href => $q->url . '?act=00010011;co=' . $company->{seq} }, "edit" ) . ' ]' );
					push ( @{ $cms->{content} },  '[ ' . $q->a({ -href => $company->{url} }, "website" ) . ' ]' ) if $company->{url};
					push ( @{ $cms->{content} },  $q->end_div );
					push ( @{ $cms->{content} },  $q->end_div );
					push ( @{ $cms->{content} },  $q->br );
				}
			}
		}
		push ( @{ $cms->{content} },  $q->hr({ -class => 'mini' }) );
		push ( @{ $cms->{content} },  $q->br );
	}
	elsif ( $vars->{act} =~ /^1010$/ ) {
		# Add company
		push ( @{ $cms->{content} },  $q->h3( "Add Company" ) );
		push ( @{ $cms->{content} },  $q->hr({ -class => 'mini' }) );
		push ( @{ $cms->{content} },  $q->br );
		if ( $vars->{name} && $vars->{zip} && $vars->{phone} && $vars->{address} ) {
			my %entity = (
				name => $vars->{name},
				url => $vars->{url},
				address => $vars->{address},
				address2 => $vars->{address2},
				zip => $vars->{zip},
				phone => $vars->{phone},
				fax => $vars->{fax},
			);
			my $ret = $c->insert_company( \%entity );
			if ( !$ret ) {
				push ( @{ $cms->{content} }, "OH NOES! YOUR POP3 HAS BEEN IMAP'ed: " . $c->{errstr} );
			}
			else {
				push ( @{ $cms->{content} }, "Company successfully added!" );
				push ( @{ $cms->{content} }, $q->br );
			}
		}
		else {
			push ( @{ $cms->{content} },  $q->start_form );
			push ( @{ $cms->{content} },  $q->hidden({
				-name => 'act',
				-value => '1010',
				-override => 1,
			}) );
			push ( @{ $cms->{content} },  $q->br );
			push ( @{ $cms->{content} },  '<label class="sleek-bold" for="name">Company Name:</label>' );
			push ( @{ $cms->{content} },  $q->textfield(
				-name => 'name',
				-id => 'name',
				-class => 'sleek',
				-maxlength => 16,
			) );
			push ( @{ $cms->{content} },  $q->br );
			push ( @{ $cms->{content} },  '<label class="sleek" for="url">URL:</label>' );
			push ( @{ $cms->{content} },  $q->textfield(
				-name => 'url',
				-id => 'url',
				-class => 'sleek',
				-maxlength => 255,
			) );
			push ( @{ $cms->{content} },  $q->br );
			push ( @{ $cms->{content} },  '<label class="sleek-bold" for="phone">Phone:</label>' );
			push ( @{ $cms->{content} },  $q->textfield(
				-name => 'phone',
				-id => 'phone',
				-class => 'sleek',
				-maxlength => 16,
			) );
			push ( @{ $cms->{content} },  $q->br );
			push ( @{ $cms->{content} },  '<label class="sleek" for="fax">Fax:</label>' );
			push ( @{ $cms->{content} },  $q->textfield(
				-name => 'fax',
				-id => 'fax',
				-class => 'sleek',
				-maxlength => 16,
			) );
			push ( @{ $cms->{content} },  $q->br );
			push ( @{ $cms->{content} },  '<label class="sleek-bold" for="address">Street Address:</label>' );
			push ( @{ $cms->{content} },  $q->textfield(
				-name => 'address',
				-id => 'address',
				-class => 'sleek',
				-maxlength => 48,
			) );
			push ( @{ $cms->{content} },  $q->br );
			push ( @{ $cms->{content} },  '<label class="sleek" for="address2">Address Line 2:</label>' );
			push ( @{ $cms->{content} },  $q->textfield(
				-name => 'address2',
				-id => 'address2',
				-class => 'sleek',
				-maxlength => 48,
			) );
			push ( @{ $cms->{content} },  $q->br );
			push ( @{ $cms->{content} },  '<label class="sleek-bold" for="zip">Zipcode:</label>' );
			push ( @{ $cms->{content} },  $q->textfield(
				-name => 'zip',
				-id => 'zip',
				-class => 'sleek-small',
				-maxlength => 5,
			) );
			push ( @{ $cms->{content} },  $q->br );
			push ( @{ $cms->{content} },  $q->hr({ -class => 'mini' }) );
			push ( @{ $cms->{content} },  $q->start_div({ -class => 'sleek-button' }) );
			push ( @{ $cms->{content} },  $q->submit({
				-class => 'sleek-button',
				-value => 'Add!',
				-id => 'submit',
				-name => 'submit',
			}) );
			push ( @{ $cms->{content} },  $q->end_div );
			push ( @{ $cms->{content} },  $q->end_form );
		}
		push ( @{ $cms->{content} },  $q->br );
		push ( @{ $cms->{content} },  $q->hr({ -class => 'mini' }) );
		push ( @{ $cms->{content} },  $q->br );
	}
	else {
		push ( @{ $cms->{content} }, 'Odd, you have somehow entered an invalid option. Please try again. If you continue to have issues, please contact your system administrator.' );
	}
}

else {
	push ( @{ $cms->{content} }, 'Welcome to ShellShark Networks Contact Management System. Please choose an option to your left to get started.' );
}

print $cms->publicize( $q );

exit;

sub commie {
	local $_ = shift;
	1 while s/^([-+]?\d+)(\d{3})/$1,$2/;
	return $_;
}


1;
