package TestApp::Controller::Basic;
use warnings;
use strict;

use base qw(Catalyst::Controller::Constraints);

__PACKAGE__->config(
    constraints => {
        WillWork => sub { 1 },
    },
);

#
#   To see if we can dispatch.
#
sub index : Private { $_[1]->res->body( 'basic index' ) }

#
#   Test the class of the actions.
#
sub class : Chained PathPart('basic/class') Constraints( WillWork foo ) {
    my ( $self, $c ) = @_;
    $c->res->body( ref $self->action_for( 'class' ) );
}

#
#   Testing if uri_for's alright
#
sub uri_for : Chained PathPart('basic/uri_for') Constraints( WillWork foo ) {
    my ( $self, $c ) = @_;
    $c->res->body( $c->uri_for( $self->action_for( 'uri_for' ), 23 ) );
}

1;
