#!/usr/bin/perl

use warnings;
use strict;
use Common;
use Contacts;
use Accounts;
use WorkOrders;
use WWW::CMS;
use Auth::Sticky;

## The purpose of this is to act as a director to the different functions
## handled by Contacts.pm, Accounts.pm and WorkOrders.pm, and to run the
## output to WWW::CMS.

## Currently moving everything out of contacts.pl, wo.pl, accounts.pl into
## their respective section's module to clean up quite a bit.

## Authentication should probably happen here too via Auth::Sticky

## Should go through each loaded section's module's dispatch table and see
## if it can perform the requested 'act' function. Possibly, after creating
## all object references, create one big dispatch table by concatinating
## those of all loaded sections. (good idea revd)

my $common = Common->new();
my $contacts = Contacts->new();
