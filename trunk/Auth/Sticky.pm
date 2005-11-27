#!/usr/bin/perl -wT

package Auth::Sticky;

=head1 NAME

Auth::Sticky

=over

=item COPYRIGHT

Copyright (c)2005 Bryce Porter

=back

=over

=item LICENSE

Released under the terms of the General Public License

=back

=cut

use strict;
use Digest::MD5		qw( md5_hex );
use DBI;
use CGI			qw( :standard );

=head1 FUNCTIONS

=over

=item new()

Creates a blessed self object reference

Takes a hashref of configuration parameters:
	use_prior_db:	Optional previously defined DBI object reference
	use_prior_cgi:	Optional previously defined CGI object reference
	dbtype:		The type of database we will be connecting to (mysql, etc) NOTE: Must be supported by DBI
	dbname:		The name of the database we are authenticating with
	dbuser:		The www_user on that database that has SELECT,UPDATE,INSERT,DELETE privileges
	dbpass:		The password for that user

Returns object reference on success; nothing on failure

=back

=cut

sub new {

	print STDERR "DEBUG: Auth::Sticky->new()\n";

	my $class = shift;
	my $self = { };
	bless $self, $class;

	my $conf = shift || return;

	if ( $conf->{use_prior_db} ) {
		# Should check to see what type of element this is
		$self->{dbh} = $conf->{use_prior_db};
	}
	else {
		if ( $conf->{dbtype} && $conf->{dbname} && $conf->{dbuser} && $conf->{dbpass} ) {
			$self->{dbh} = DBI->connect( "dbi:$conf->{dbtype}:$conf->{dbname}", $conf->{dbuser}, $conf->{dbpass} );
			if ( !$self->{dbh} ) {
				$self->{ERRSTR} = "Failed to connect to database: ", DBI::errstr;
				return;
			}
		}
	}
	
	if ( $conf->{use_prior_cgi} ) {
		$self->{query} = $conf->{use_prior_cgi};
	}
	else {
		$self->{query} = new CGI;
		if ( !$self->{query} ) {
			$self->{ERRSTR} = "Failed to create CGI object: ", $!;
			return;
		}
	}

	return $self;
}

=over

=item has_auth()

Checks to see if www_user is currently authenticated and valid.
Takes one optional argument of the SQL unique sequential auth number (as opposed to getting it from cookie)
Returns 1 on success (true).
Upon failure, returns nothing and sets $self->{ERRSTR}

=back
 
=cut

sub has_auth {

	print STDERR "DEBUG: Auth::Sticky->has_auth()\n";

	my ( $self, $p_tok ) = @_;
	
	if ( my $token = $p_tok || $self->get_auth_token ) {
		# Client has a token, see if it's valid
		if ( $self->is_valid_token( $token ) ) {
			# And it appears to be...
			print STDERR "DEBUG: Auth::Sticky->has_auth() = $token\n";
			return 1;
		}
		else {
			# Uh oh...
			$self->{ERRSTR} = 'Client passed invalid token';
			return;
		}
	}
	else {
		print STDERR "DEBUG: Auth::Sticky->has_auth() = undef\n";
		return;
	}
}

=over

=item get_auth_token()

Gets the authentication token from the client's cookie.
Takes no arguments.
Returns token number on success.
Upon failure, returns nothing and sets $self->{ERRSTR}

=back

=cut

sub get_auth_token {

	print STDERR "DEBUG: Auth::Sticky->get_auth_token()\n";

	my $self = shift;

	if ( my $token = $self->{query}->cookie(	-name	=>	'authen'	) ) {
		return $token;
	}
	else {
		return;
	}
}

=over

=item is_valid_token()

Verifies that the given token is valid.
Takes the token unique number as an argument.
On success, sets $self->{token} to the token number (UID), and returns 1.
Returns nothing on failure.

=back

=cut

sub is_valid_token {

	print STDERR "DEBUG: Auth::Sticky->is_valid_token()\n";

	my $self = shift;
	my $token = shift;

	$self->{sth} = $self->{dbh}->prepare( 'SELECT ip FROM www_auth WHERE uid = ? ORDER BY intime DESC LIMIT 1' ) || do {
		$self->{ERRSTR} = 'Failed to prepare SQL query: ', DBI::errstr;
		return;
	};
	$self->{sth}->execute( $token ) || do {
		$self->{ERRSTR} = 'Failed to execute SQL querh: ', DBI::errstr;
		$self->{sth}->finish;
		return;
	};
	my $row = $self->{sth}->fetchrow_hashref;
	$self->{sth}->finish;
	if ( !$row->{ip} ) {
		# This one is a no go :P
		return;
	}
	else {
		# Good so far... make sure IP matches
		my $remote = $self->{query}->remote_host();
		if ( !$remote ) {
			$self->{ERRSTR} = 'Could not verify authentication token: Failed to extract client IP address';
			return;
		}
		if ( $row->{ip} eq $remote ) {
			# Good to go
			$self->{token} = $token;
			return 1;
		}
	}
}

=over

=item get_priv()

Gets the priveledge level from the www_users table associated with the given token.
Takes the unique id from the www_auth table as an argument.
Returns priveledge level on success; sets $self->{ERRSTR} and returns nothing on failure.

=back

=cut

sub get_priv {

	print STDERR "DEBUG: Auth::Sticky->get_priv()\n";

	my $self = shift;

	if ( my $token = $self->get_auth_token ) {
		print STDERR "get_priv(): $token\n";
		if ( $self->is_valid_token( $token ) ) {
			$self->{sth} = $self->{dbh}->prepare( 'SELECT priv FROM www_user WHERE seq = ?' ) || do {
				$self->{ERRSTR} = 'Failed to prepare SQL query: ', DBI::errstr;
				return;
			};
			$self->{sth}->execute( $token ) || do {
				$self->{ERRSTR} = 'Failed to execute SQL query: ', DBI::errstr;
				return;
			};
			my $row = $self->{sth}->fetchrow_hashref;
			$self->{sth}->finish;
			if ( !$row->{priv} ) {
				$self->{ERRSTR} = 'Priveledge not defined in SQL';
				return;
			}
			return $row->{priv};
		}
		else {
			$self->{ERRSTR} = 'Recieved an invalid token here: Auth::Sticky->get_priv()';
			return;
		}
	}
}

=over

=item set_auth()

This function sets up the www_auth table to say that our client is authorized.
Takes user's unique SQL id as argument (see validate()).
Returns a cookie on success; sets $self->{ERRSTR} and returns nothing on error.

=back

=cut

sub set_auth {

	print STDERR "DEBUG: Auth::Sticky->set_auth()\n";

	my ( $self, $id ) = @_;

	$self->{sth} = $self->{dbh}->prepare( 'INSERT INTO www_auth VALUES(NULL,?,NOW()+0,3600,?)' ) or do {
		$self->{ERRSTR} = 'Failed to prepare SQL query: ' . DBI::errstr;
		return;
	};
	$self->{sth}->execute( $self->{query}->remote_host, $id ) or do {
		$self->{ERRSTR} = 'Failed to execute SQL query: ' . DBI::errstr;
		$self->{sth}->finish;
		return;
	};
	$self->{sth}->finish;
	$self->{sth} = $self->{dbh}->prepare( 'SELECT seq FROM www_auth WHERE uid = ? AND ip = ?' ) or do {
		$self->{ERRSTR} = 'Failed to prepare SQL query: ' . DBI::errstr;
		return;
	};
	$self->{sth}->execute( $id, $self->{query}->remote_host ) or do {
		$self->{ERRSTR} = 'Failed to execute SQL query: ' . DBI::errstr;
		$self->{sth}->finish;
		return;
	};
	
	my $token = $self->{sth}->fetchrow_hashref;
	
	$self->{sth}->finish;

	my $cookie = $self->{query}->cookie(
		-name		=>	'authen',
		-value		=>	$token->{seq},
		-expires	=>	'+1d',
		-path		=>	'/cgi-bin',
		-domain		=>	'.shellshark.net',
		-secure		=>	0,
	);

	print STDERR "DEBUG: Auth::Sticky->set_auth( $id ) = $cookie\n";
	
	return $cookie;
}

=over

=item unset_auth()

This method must be called to unset someone's login in the database, as well as trump the cookie on thier browser.
Takes no arguments (automatically grabs the authentication token regarding the current session)
Returns a trump cookie on success; sets $self->{ERRSTR} and returns nothing on failure.

=back

=cut

sub unset_auth {

	print STDERR "DEBUG: Auth::Sticky->unset_auth()\n";

	my $self = shift;
	
	# Get token
	my $token = $self->get_auth_token;
	
	# Verify authentication token first
	if ( $self->is_valid_token( $token ) ) {
		# Cool, checks out. Dont delete just this session, but all previous sessions for www_user as well
		my $sth = $self->{dbh}->prepare( 'DELETE FROM www_auth WHERE uid = ?' ) || do {
			$self->{ ERRSTR } = "Failed to prepare SQL query: $self->{dbh}->errstr";
			return;
		};
		$sth->execute( $self->{token} ) || do {
			$self->{ ERRSTR } = "Failed to execute SQL query: $self->{dbh}->errstr";
			$sth->finish;
			return;
		};
		
		# Now, send a cookie that has already expired
		my $cookie = $self->{query}->cookie(
			-name		=>	'authen',
			-value		=>	$token,
			-expires	=>	'-1d',
			-path		=>	'/cgi-bin/trax',
			-domain		=>	'.heart.net',
			-secure		=>	0,
		);
		
		return $cookie;
	}
	else {
		# Uh ohh
		$self->{ ERRSTR } = 'Failed to validate authentication token';
		return;
	}
}

=over

=item validate()

This function validates a username and password.
Takes a username and password as arguments.
Returns user's unique SQL id on success; sets $self->{ERRSTR} and returns nothing on error.

=back

=cut

sub validate {
	my $self = shift;
	
	my ( $un, $pw ) = @_;
	print STDERR "$0: DEBUG: Auth::Sticky->validate('$un', '$pw')\n";

	$self->{sth} = $self->{dbh}->prepare( 'SELECT seq,pw,priv FROM www_user WHERE un = ?' ) || do {
		$self->{ERRSTR} = 'Failed to prepare SQL query: ', DBI::errstr;
		return;
	};
	$self->{sth}->execute( $un ) || do {
		$self->{ERRSTR} = 'Failed to execute SQL query: ', DBI::errstr;
		$self->{sth}->finish;
		return;
	};
	my $row = $self->{sth}->fetchrow_hashref;
	$self->{sth}->finish;
	if ( !$row->{pw} ) {
		$self->{ERRSTR} = 'No such user: ', $un;
		return;
	}
	print STDERR "$0: DEBUG: Auth::Sticky->validate(): Thiers: '$row->{pw}'; Mine: '" . md5_hex( $pw ) . "'\n";
	if ( $row->{pw} eq md5_hex( $pw ) ) {
		return $row->{seq};
	}
	else {
		$self->{ERRSTR} = 'Bad password: ', $pw;
		return;
	}
}

=over

=item Terminator()

This method must be called to properly shutdown all objects and do final cleanup.
Takes no arguments.
Returns 1 on success; sets $self->{ERRSTR} and returns nothing on failure.

=back

=cut

sub Terminator {
	my $self = shift;
	$self->{dbh}->disconnect or do {
		$self->{ERRSTR} = "Failed to destroy database connection: ", DBI::errstr;
		return;
	};
	$self->{query} = undef;
	return 1;
}

1;
