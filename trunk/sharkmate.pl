#!/usr/bin/perl

use warnings;
use strict;
use Sharkmate::Common;
use WWW::CMS;
use Auth::Sticky;

package Sharkmate;

## Currently moving everything out of contacts.pl, wo.pl, accounts.pl into
## their respective section's module to clean up quite a bit.
##	contacts.pl => done

## Authentication should probably happen here too via Auth::Sticky

sub main {
	my $self = { };
	bless $self;

	my @out;

	$self->{_release} = '0.0.0';
	$self->{_common} = Sharkmate::Common->new();
	$self->{_cms} = WWW::CMS->new({
		TemplateBase	=>	$self->{_common}->{conf}->{TemplateBase},
		Module		=>	$self->{_common}->{conf}->{Module}
	});

	# Autoload these function handlers
	my @autoload = (
		'Sharkmate::Contacts',
		'Sharkmate::Accounts',
		'Sharkmate::WorkOrders',
	);

	foreach my $namespace ( @autoload ) {
		# Thanks to buu for the require suggestions
		my $file = $namespace;
		$file =~ s#::#/#g;
		$file =~ s/$/.pm/;
		require $file; 
		$self->{plugins}->{$namespace} = $namespace->new();

		for ( keys %{ $self->{plugins}->{$namespace}->{dispatch} } ) {
			$self->{dispatch}->{$_}->{obj} = $self->{plugins}->{$namespace};
			$self->{dispatch}->{$_}->{method} = $self->{plugins}->{$namespace}->{dispatch}->{$_};
		}

		print STDERR "Loaded plugin: '$file'\n";
	}

	if ( $self->{_common}->{vars}->{act} ) {
		# 'act' was passed in, see if we have a handler for it

		if ( $self->{dispatch}->{ $self->{_common}->{vars}->{act} } ) {
			# Indeed we do, run it and pass it the three standard variables (DBI ref, CGI ref, hashref of CGI variables)
			my $dbh = $self->{_common}->{dbh};
			my $q = $self->{_common}->{query};
			my $vars = $self->{_common}->{vars};
			my $obj = $self->{dispatch}->{ $self->{_common}->{vars}->{act} }->{obj};
			my $method = $self->{dispatch}->{ $self->{_common}->{vars}->{act} }->{method};
			my $out = $obj->$method( $dbh, $q, $vars ) or do {
				print STDERR "Error dispatching '$self->{_common}->{vars}->{act}'\n";
				push ( @{ $self->{_cms}->{content} }, "<h1 style='color:red'>Fatal Error</h1><hr />A fatal error has occured, please contact your system administrator." );
			};

			push ( @{ $self->{_cms}->{content} }, @{ $out } ) if $out;
		}
		else {
			# That's a negative
			print STDERR "Do not have a dispatch entry for requested action '$self->{_common}->{vars}->{act}'\n";
			push ( @{ $self->{_cms}->{content} }, "<h1 style='color:red'>Error</h1><hr />No handler exists for requested action. Please go back and try again." );
		}
	}
	else {
		# No action specified, run the default action
		$self->{_cms}->{PageName} = 'Welcome';
		push ( @{ $self->{_cms}->{content} }, "Welcome to SharkMate $self->{_release}" );
	}

	push ( @out, $self->{_common}->{query}->header );
	push ( @out, $self->{_cms}->publicize( $self->{_common}->{query} ) );

	return @out;
}

print main();

1;
