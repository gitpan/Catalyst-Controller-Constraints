package TestApp::Controller::OtherAttrName;
use warnings;
use strict;

use base qw(Catalyst::Controller::Constraints);

__PACKAGE__->config(
	constraint_attribute => 'Sig',
	constraints => {
		IsTrue => {
			post_filter => sub { $_[1]->res->body( $_ ) },
		},
	},
);

sub foo : Chained PathPart('signatures/otherattrname') Sig( IsTrue foo ) { }

1;
