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
my $cms = WWW::CMS->new({	TemplateBase	=>	'/home/x86/webmodules',
				Module		=>	'contacts.xml'	});

print $q->header;
$cms->{PageName} = 'Contact Management';
if ( $vars->{act} ) {
	if ( $vars->{act} =~ /^0000$/ ) {
		my %prefixes = (
			1 => 'Mr.',
			2 => 'Ms.',
			3 => 'Mrs.',
			4 => 'Dr.',
		);
		push ( @{ $cms->{content} },  $q->h3( "View all contacts" ) );
		push ( @{ $cms->{content} },  $q->hr({ -class => 'mini'}) );
		push ( @{ $cms->{content} },  $q->br );
		my $contacts = $c->view_all_contacts;
		my $matches = scalar( @{ $contacts } );
		push ( @{ $cms->{content} },  $q->start_div({ -align => 'center' }) );
		if ( $matches < 1 ) {
			push ( @{ $cms->{content} },  "Sorry, you suck too much to have any contacts" );
			push ( @{ $cms->{content} },  $q->end_div );
		}
		else {
			push ( @{ $cms->{content} },  "There is $matches contact on record" ) if $matches <= 1;
			push ( @{ $cms->{content} },  "There are " . commie( $matches ) . " contacts on record" ) if $matches > 1;
			push ( @{ $cms->{content} },  $q->end_div );
			push ( @{ $cms->{content} },  $q->br );
			my $count;
			foreach my $contact ( @{ $contacts } ) {
				$count++;
				(my $company = $contact->{company}) =~ s/($vars->{crit})/\<b\>\<u\>$1\<\/u\>\<\/b\>/gi;
				(my $fname = $contact->{fname}) =~ s/($vars->{crit})/\<b\>\<u\>$1\<\/u\>\<\/b\>/gi;
				(my $lname = $contact->{lname}) =~ s/($vars->{crit})/\<b\>\<u\>$1\<\/u\>\<\/b\>/gi;
				(my $email = $contact->{email}) =~ s/($vars->{crit})/\<b\>\<u\>$1\<\/u\>\<\/b\>/gi;
				(my $city = $contact->{city}) =~ s/($vars->{crit})/\<b\>\<u\>$1\<\/u\>\<\/b\>/gi;
				push ( @{ $cms->{content} },  $q->start_div({ -class => 'block' }) );
				push ( @{ $cms->{content} },  $q->start_div({ -class => 'block-title' }) );
				push ( @{ $cms->{content} },  $company );
				push ( @{ $cms->{content} },  $q->end_div );
				push ( @{ $cms->{content} },  $q->start_ul({ -class => 'sleek' }) );
				push ( @{ $cms->{content} },  $q->start_li . $prefixes{$contact->{prefix}} . ' ' . join( ", ", $lname, $fname ) . $q->end_li );
				push ( @{ $cms->{content} },  $q->start_li . 'url: ' . $contact->{url} . $q->end_li ) if $contact->{url};
				push ( @{ $cms->{content} },  $q->br );
				push ( @{ $cms->{content} },  $q->start_li . $contact->{address} . $q->end_li );
				push ( @{ $cms->{content} },  $q->start_li . $contact->{suite} . $q->end_li ) if $contact->{suite};
				push ( @{ $cms->{content} },  $q->start_li . join ( ", ", $city, $contact->{state}, $contact->{zip} ) . $q->end_li );
				push ( @{ $cms->{content} },  $q->br );
				push ( @{ $cms->{content} },  $q->start_li . 'em: ' . $email . $q->end_li );
				push ( @{ $cms->{content} },  $q->start_li . 'ph: ' . $contact->{phone} );
				push ( @{ $cms->{content} },  " x " . $contact->{ext} ) if $contact->{ext};
				push ( @{ $cms->{content} },  $q->end_li );
				push ( @{ $cms->{content} },  $q->start_li . 'ce: ' . $contact->{cell} . $q->end_li ) if $contact->{cell};
				push ( @{ $cms->{content} },  $q->start_li . 'fx: ' . $contact->{fax} . $q->end_li ) if $contact->{fax};
				#push ( @{ $cms->{content} },  $q->br );
				push ( @{ $cms->{content} },  $q->start_div({ -align => 'center' }) );
				push ( @{ $cms->{content} },  '[ ' . $q->a({ -href => $q->url . '?act=0101;co=' . $contact->{seq} }, "delete" ) . ' ]' );
				push ( @{ $cms->{content} },  '[ ' . $q->a({ -href => $q->url . '?act=0011;co=' . $contact->{seq} }, "edit" ) . ' ]' );
				push ( @{ $cms->{content} },  '[ ' . $q->a({ -href => 'mailto:' . $contact->{email} }, "e-mail" ) . ' ]' );
				push ( @{ $cms->{content} },  '[ ' . $q->a({ -href => $q->url . '?act=0100;co=' . $contact->{seq} }, $c->get_num_notes( $contact->{seq} ) . " notes" ) . ' ]' );
				push ( @{ $cms->{content} },  '[ ' . $q->a({ -href => $contact->{url} }, "website" ) . ' ]' ) if $contact->{url};
				push ( @{ $cms->{content} },  $q->end_div );
				push ( @{ $cms->{content} },  $q->end_ul );
				push ( @{ $cms->{content} },  $q->end_div );
				push ( @{ $cms->{content} },  $q->br );
			}
		}
		push ( @{ $cms->{content} },  $q->hr({ -class => 'mini' }) );
		push ( @{ $cms->{content} },  $q->br );
	}
	elsif ( $vars->{act} =~ /^0001$/ ) {
		push ( @{ $cms->{content} },  $q->h3( "Find Contacts" ) );
		push ( @{ $cms->{content} },  $q->hr({ -class => 'mini'}) );
		push ( @{ $cms->{content} },  $q->start_form );
		push ( @{ $cms->{content} },  $q->hidden(	-name		=> 'act',
								-value		=> '0001',
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
			my $contacts = $c->find_contact( $vars->{crit} );
			my $matches = scalar( @{$contacts} );
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
					push ( @{ $cms->{content} },  $q->start_div({ -class => 'block' }) );
					push ( @{ $cms->{content} },  $q->start_div({ -class => 'block-title' }) );
					push ( @{ $cms->{content} },  $company );
					push ( @{ $cms->{content} },  $q->end_div );
					push ( @{ $cms->{content} },  $q->start_ul({ -class => 'sleek' }) );
					push ( @{ $cms->{content} },  $q->start_li . $prefixes{$contact->{prefix}} . ' ' . join( ", ", $lname, $fname ) . $q->end_li );
					push ( @{ $cms->{content} },  $q->start_li . $url . $q->end_li ) if $url;
					push ( @{ $cms->{content} },  $q->br );
					push ( @{ $cms->{content} },  $q->start_li . $address . $q->end_li );
					push ( @{ $cms->{content} },  $q->start_li . $suite . $q->end_li ) if $suite;
					push ( @{ $cms->{content} },  $q->start_li . join ( ", ", $city, $contact->{state}, $zip ) . $q->end_li );
					push ( @{ $cms->{content} },  $q->br );
					push ( @{ $cms->{content} },  $q->start_li . 'em: ' . $email . $q->end_li );
					push ( @{ $cms->{content} },  $q->start_li . 'ph: ' . $phone );
					push ( @{ $cms->{content} },  " x " . $ext ) if $ext;
					push ( @{ $cms->{content} },  $q->end_li );
					push ( @{ $cms->{content} },  $q->start_li . 'ce: ' . $cell . $q->end_li . $q->br ) if $cell;
					push ( @{ $cms->{content} },  $q->start_li . 'fx: ' . $fax . $q->end_li ) if $fax;
					#push ( @{ $cms->{content} },  $q->br );
					push ( @{ $cms->{content} },  $q->start_div({ -align => 'center' }) );
					push ( @{ $cms->{content} },  '[ ' . $q->a({ -href => $q->url . '?act=0101;co=' . $contact->{seq} }, "delete" ) . ' ]' );
					push ( @{ $cms->{content} },  '[ ' . $q->a({ -href => $q->url . '?act=0011;co=' . $contact->{seq} }, "edit" ) . ' ]' );
					push ( @{ $cms->{content} },  '[ ' . $q->a({ -href => 'mailto:' . $contact->{email} }, "e-mail" ) . ' ]' );
					push ( @{ $cms->{content} },  '[ ' . $q->a({ -href => $q->url . '?act=0100;co=' . $contact->{seq} }, $c->get_num_notes( $contact->{seq} ) . " notes" ) . ' ]' );
					push ( @{ $cms->{content} },  '[ ' . $q->a({ -href => $contact->{url} }, "website" ) . ' ]' ) if $contact->{url};
					push ( @{ $cms->{content} },  $q->end_div );
					push ( @{ $cms->{content} },  $q->end_div );
					push ( @{ $cms->{content} },  $q->br );
				}
			}
		}
		push ( @{ $cms->{content} },  $q->hr({ -class => 'mini' }) );
		push ( @{ $cms->{content} },  $q->br );
	}
	elsif ( $vars->{act} =~ /^0010$/ ) {
		push ( @{ $cms->{content} },  $q->h3( "Add Contact" ) );
		push ( @{ $cms->{content} },  $q->hr({ -class => 'mini' }) );
		push ( @{ $cms->{content} },  $q->br );
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
			my $ret = $c->insert_contact( \%entity );
			if ( !$ret ) {
				push ( @{ $cms->{content} }, "OH NOES! YOUR POP3 HAS BEEN IMAP'ed: " . $c->{errstr} );
			}
			else {
				push ( @{ $cms->{content} }, "Contact successfully added!" );
				push ( @{ $cms->{content} }, $q->br );
			}
		}
		else {
			my $companies = $wo->get_all_companies();
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
			push ( @{ $cms->{content} },  $q->start_form );
			push ( @{ $cms->{content} },  $q->hidden({
				-name => 'act',
				-value => '0010',
				-override => 1,
			}) );
			push ( @{ $cms->{content} },  '<label class="sleek-bold" for="prefix">Salutation:</label>' );
			push ( @{ $cms->{content} },  $q->popup_menu(
				-name => 'prefix',
				-values => \%salutations,
				-labels => \%salutations,
				-class => 'sleek',
			) );
			push ( @{ $cms->{content} },  $q->br );
			push ( @{ $cms->{content} },  '<label class="sleek-bold" for="fname">First Name:</label>' );
			push ( @{ $cms->{content} },  $q->textfield(
				-name => 'fname',
				-id => 'fname',
				-class => 'sleek',
				-maxlength => 16,
			) );
			push ( @{ $cms->{content} },  $q->br );
			push ( @{ $cms->{content} },  '<label class="sleek-bold" for="lname">Last Name:</label>' );
			push ( @{ $cms->{content} },  $q->textfield(
				-name => 'lname',
				-id => 'lname',
				-class => 'sleek',
				-maxlength => 16,
			) );
			push ( @{ $cms->{content} },  $q->br );
			push ( @{ $cms->{content} },  '<label class="sleek-bold" for="email">E-Mail:</label>' );
			push ( @{ $cms->{content} },  $q->textfield(
				-name => 'email',
				-id => 'email',
				-class => 'sleek',
				-maxlength => 48,
			) );
			push ( @{ $cms->{content} },  $q->br );
			push ( @{ $cms->{content} },  $q->hr({ -class => 'mini' }) );
			push ( @{ $cms->{content} },  '<label class="sleek-bold" for="company">Company:</label>' );
			push ( @{ $cms->{content} },  $q->popup_menu(
				-name => 'company',
				-id => 'company',
				-class => 'sleek-large',
				-values => $companies,
				-labels => $companies,
			) );
			push ( @{ $cms->{content} },  $q->br );
			push ( @{ $cms->{content} },  '<label class="sleek-bold" for="url">URL:</label>' );
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
			push ( @{ $cms->{content} },  '<label class="sleek" for="ext">Extension:</label>' );
			push ( @{ $cms->{content} },  $q->textfield(
				-name => 'ext',
				-id => 'ext',
				-class => 'sleek-small',
				-maxlength => 6,
			) );
			push ( @{ $cms->{content} },  $q->br );
			push ( @{ $cms->{content} },  '<label class="sleek" for="cell">Cell:</label>' );
			push ( @{ $cms->{content} },  $q->textfield(
				-name => 'cell',
				-id => 'cell',
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
			push ( @{ $cms->{content} },  '<label class="sleek" for="suite">Suite:</label>' );
			push ( @{ $cms->{content} },  $q->textfield(
				-name => 'suite',
				-id => 'suite',
				-class => 'sleek-small',
				-maxlength => 12,
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
			push ( @{ $cms->{content} },  '<label class="sleek-bold" for="prefer">Prefer Contact Via:</label>' );
			push ( @{ $cms->{content} },  $q->popup_menu(
				-name => 'prefer',
				-values => \%pcont,
				-labels => \%pcont,
				-class => 'sleek',
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
	elsif ( $vars->{act} =~ /^0011$/ ) {
		push ( @{ $cms->{content} },  $q->h3( "Edit Contact" ) );
		push ( @{ $cms->{content} },  $q->hr({ -class => 'mini' }) );
		push ( @{ $cms->{content} },  $q->br );
		if ( $vars->{prefix} && $vars->{fname} && $vars->{lname} && $vars->{company} && $vars->{zip} && $vars->{phone} && $vars->{address} && $vars->{email} && $vars->{prefer} && $c->lookup_contact_by_seq( $vars->{co} ) ) {
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
			my $ret = $c->update_contact_by_seq( $vars->{co}, \%entity );
			if ( !$ret ) {
				push ( @{ $cms->{content} }, "OH NOES! YOUR POP3 HAS BEEN IMAP'ed: " . $c->{errstr} );
			}
			else {
				push ( @{ $cms->{content} }, "Contact successfully updated!" );
				push ( @{ $cms->{content} }, $q->br );
			}
		}
		else {
			if ( $vars->{co} && (my $current = $c->lookup_contact_by_seq( $vars->{co} ) ) ) {
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
				my $clist = $c->view_all_companies;
				my %companies;
				foreach my $company ( @{ $clist } ) {
					$companies{$company->{seq}} = $company->{name}
				}
				push ( @{ $cms->{content} },  $q->start_form );
				push ( @{ $cms->{content} },  $q->hidden({
					-name => 'act',
					-value => '0011',
					-override => 1,
				}) );
				push ( @{ $cms->{content} },  $q->hidden({
					-name => 'co',
					-value => $vars->{co},
					-override => 1,
				}) );
				push ( @{ $cms->{content} },  '<label class="sleek-bold" for="prefix">Salutation:</label>' );
				push ( @{ $cms->{content} },  $q->popup_menu(
					-name => 'prefix',
					-values => \%salutations,
					-labels => \%salutations,
					-class => 'sleek',
					-selected => $current->{prefix},
					-default => $current->{prefix},
					-override => 1,
				) );
				push ( @{ $cms->{content} },  $q->br );
				push ( @{ $cms->{content} },  '<label class="sleek-bold" for="fname">First Name:</label>' );
				push ( @{ $cms->{content} },  $q->textfield(
					-name => 'fname',
					-id => 'fname',
					-class => 'sleek',
					-maxlength => 16,
					-default => $current->{fname},
					-value => $current->{fname},
				) );
				push ( @{ $cms->{content} },  $q->br );
				push ( @{ $cms->{content} },  '<label class="sleek-bold" for="lname">Last Name:</label>' );
				push ( @{ $cms->{content} },  $q->textfield(
					-name => 'lname',
					-id => 'lname',
					-class => 'sleek',
					-maxlength => 16,
					-default => $current->{lname},
					-value => $current->{lname},
				) );
				push ( @{ $cms->{content} },  $q->br );
				push ( @{ $cms->{content} },  '<label class="sleek-bold" for="email">E-Mail:</label>' );
				push ( @{ $cms->{content} },  $q->textfield(
					-name => 'email',
					-id => 'email',
					-class => 'sleek',
					-maxlength => 48,
					-default => $current->{email},
					-value => $current->{email},
				) );
				push ( @{ $cms->{content} },  $q->br );
				push ( @{ $cms->{content} },  $q->hr({ -class => 'mini' }) );
				push ( @{ $cms->{content} },  '<label class="sleek-bold" for="company">Company:</label>' );
				push ( @{ $cms->{content} },  $q->popup_menu(
					-name => 'company',
					-values => \%companies,
					-labels => \%companies,
					-class => 'sleek-large',
					-selected => $current->{company},
					-default => $current->{company},
					-override => 1,
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
				push ( @{ $cms->{content} },  '<label class="sleek" for="ext">Extension:</label>' );
				push ( @{ $cms->{content} },  $q->textfield(
					-name => 'ext',
					-id => 'ext',
					-class => 'sleek-small',
					-maxlength => 6,
					-default => $current->{ext},
					-value => $current->{ext},
					-override => 1,
				) );
				push ( @{ $cms->{content} },  $q->br );
				push ( @{ $cms->{content} },  '<label class="sleek" for="cell">Cell:</label>' );
				push ( @{ $cms->{content} },  $q->textfield(
					-name => 'cell',
					-id => 'cell',
					-class => 'sleek',
					-maxlength => 16,
					-default => $current->{cell},
					-value => $current->{cell},
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
				push ( @{ $cms->{content} },  '<label class="sleek" for="suite">Suite:</label>' );
				push ( @{ $cms->{content} },  $q->textfield(
					-name => 'suite',
					-id => 'suite',
					-class => 'sleek-small',
					-maxlength => 12,
					-default => $current->{suite},
					-value => $current->{suite},
					-override => 1,
				) );
				push ( @{ $cms->{content} },  $q->br );
				push ( @{ $cms->{content} },  '<label class="sleek-bold" for="zip">Zipcode:</label>' );
				push ( @{ $cms->{content} },  $q->textfield(
					-name => 'zip',
					-id => 'zip',
					-class => 'sleek-small',
					-maxlength => 5,
					-default => $current->{zipcode},
					-value => $current->{zipcode},
					-override => 1,
				) );
				push ( @{ $cms->{content} },  $q->br );
				push ( @{ $cms->{content} },  $q->hr({ -class => 'mini' }) );
				push ( @{ $cms->{content} },  '<label class="sleek-bold" for="prefer">Prefer Contact Via:</label>' );
				push ( @{ $cms->{content} },  $q->popup_menu(
					-name => 'prefer',
					-values => \%pcont,
					-labels => \%pcont,
					-class => 'sleek',
					-selected => $current->{prefer},
					-default => $current->{prefer},
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
	elsif ( $vars->{act} =~ /^0101$/ ) {
		if ( !$vars->{co} ) {
			push ( @{ $cms->{content} }, 'Danger, danger Will Robinson!' );
		}
		else {
			if ( $c->lookup_contact_by_seq( $vars->{co} ) ) {
				if ( $c->delete_contact_by_seq( $vars->{co} ) ) {
					push ( @{ $cms->{content} }, 'Successfully deleted contact' );
				}
				else {
					push ( @{ $cms->{content} }, 'Failed to delete contact "' . $vars->{co} . '": ' . $c->{errstr} );
				}
			}
			else {
				push ( @{ $cms->{content} }, 'Stop playin around and get to work!' );
			}
		}
	}
	elsif ( $vars->{act} =~ /^0100$/ ) {
		push ( @{ $cms->{content} },  $q->h3( "Contact Notes" ) );
		push ( @{ $cms->{content} },  $q->hr({ -class => 'mini' }) );
		push ( @{ $cms->{content} },  $q->br );
		if ( !$vars->{co} ) {
			push ( @{ $cms->{content} }, 'Danger, danger Will Robinson!' );
		}
		else {
			if ( my $notes = $c->get_contact_notes( $vars->{co} ) ) {
				my $num = $c->get_num_notes( $vars->{co} );
				push ( @{ $cms->{content} },  $q->start_div({ -align => 'center' }) );
				push ( @{ $cms->{content} },  "Found $num notes for contact" );
				push ( @{ $cms->{content} },  $q->end_div );
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
				#push ( @{ $cms->{content} },  $q->br );
				push ( @{ $cms->{content} },  $q->start_div({ -align => 'center' }) );
				push ( @{ $cms->{content} },  '[ ' . $q->a({ -href => $q->url . '?act=0110;co=' . $contact->{seq} }, "add note" ) . ' ]' );
				push ( @{ $cms->{content} },  '[ ' . $q->a({ -href => $q->url . '?act=0011;co=' . $contact->{seq} }, "edit" ) . ' ]' );
				push ( @{ $cms->{content} },  '[ ' . $q->a({ -href => 'mailto:' . $contact->{email} }, "e-mail" ) . ' ]' );
				push ( @{ $cms->{content} },  $q->end_div );
				push ( @{ $cms->{content} },  $q->end_div );
				push ( @{ $cms->{content} },  $q->br );
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
					push ( @{ $cms->{content} },  $q->start_div({ -class => 'block' }) );
					push ( @{ $cms->{content} },  $q->start_div({ -class => 'block-title' }) );
					push ( @{ $cms->{content} },  sprintf("%s %s, %s - %s:%s:%s", $months{$mo}, $day, $year, $hour, $min, $sec ) );
					push ( @{ $cms->{content} },  $q->end_div );
					push ( @{ $cms->{content} },  $q->start_ul({ -class => 'sleek' }) );
					push ( @{ $cms->{content} },  $q->br );
					push ( @{ $cms->{content} },  $note->{note} );
					push ( @{ $cms->{content} },  $q->br, $q->br );
					push ( @{ $cms->{content} },  $q->start_div({ -align => 'center' }) );
					push ( @{ $cms->{content} },  '[ ' .  $q->a({ -href => $q->url . '?act=0111;ni=' . $note->{seq} }, 'delete' ) . ' ]' );
					push ( @{ $cms->{content} },  $q->end_div );
					push ( @{ $cms->{content} },  $q->end_ul );
					push ( @{ $cms->{content} },  $q->end_div );
					push ( @{ $cms->{content} },  $q->br );
				}
			}
			else {

			}
		}
	}
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
				#push ( @{ $cms->{content} },  $q->br );
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
