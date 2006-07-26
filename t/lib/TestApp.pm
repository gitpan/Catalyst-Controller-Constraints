package TestApp;
use warnings;
use strict;

use Catalyst::Runtime 5.7;
use Catalyst qw/
    -Debug
/;

__PACKAGE__->config(
    name => 'TestApp',
    root => '/road/to/nowhere',
    constraints => {
        AppWide => qr/bar/,
        AppWideMerge => sub { /bar/ },
        AppWideMergeOR => {
            check => sub { /bar/ },
            on_fail => '/signatures/fail_handler',
        },
    }
);
__PACKAGE__->setup;

#
#   Just for the basic "dispatching works" tests
#
sub index : Private { }

sub end : Private {
    my ( $self, $c ) = @_;
    if ( scalar @{ $c->error } ) {
        $c->res->body( 'ERRORS: ' . join '; ', @{ $c->error } );
        $c->clear_errors;
        $c->res->status(500);
    }
}

1;
