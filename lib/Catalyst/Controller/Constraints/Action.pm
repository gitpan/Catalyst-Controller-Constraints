=head1 NAME

Catalyst::Controller::Constraints::Action - Action proxy class

=cut

package Catalyst::Controller::Constraints::Action;
use warnings;
use strict;

use Carp;
use Catalyst::Controller::Constraints::Argument;
use base qw(Catalyst::Action);

use overload
    '""'     => sub { $_[0]->reverse },
    '&{}'    => sub { my $self = shift; sub { $self->execute(@_); }; },
    fallback => 1,
    ;

use Class::Delegator
    send => [qw(
        class
        namespace
        reverse
        attributes
        name
        code
        execute
        match
    )],
    to => '_original_action',
    ;

__PACKAGE__->mk_accessors(qw(
    _original_action
    _arguments
));

my %CLASS = (
    argument => 'Catalyst::Controller::Constraints::Argument',
);

=head1 METHODS

=head2 new

Constructor. Stores action and prepares arguments at startup time.

=cut

sub new {
    my ( $class, $controller, $action ) = @_;
    my $self = bless {} => $class;

    $self->_original_action( $action );
        # store the original action for later use and delegation.

    $self->{ $_ } = $action->{ $_ } for keys %$action;
        # this is a nasty hack because catalyst accesses the action
        # object sometimes just as hash.

    $self->_arguments([]);
    $self->_prepare_arguments( $controller, $action )
        or return $action;
        # invoke the instantiation and ininitalization of the argument
        # objects, including their constraints.

    return $self;
}

=head2 __fetch_attribute_name

Returns the current context's name for constraint attributes.

=cut

sub __fetch_attribute_name {
    my ( $self, $controller ) = @_;
    return $controller->config->{ constraint_attribute }
        || $controller->{ application }->config->{ constraint_attribute }
        || 'Constraints';
        # return the current controllers name for constraint attributes.
        # priority goes as: controller config, application config, default.
}

=head2 _deconstruct_constraint

Parses the parameter to the constraint attribute.

=cut

sub _deconstruct_constraint {
    my ( $self, $name ) = @_;

    if ( $name and $name =~ s/^(.+?)\[(.*)\]$/$1/ ) {
        return $name, $2;
    }

    return $name;
}

=head2 _prepare_arguments

Creates and prepares this action's argument objects on startup time.

=cut

sub _prepare_arguments {
    my ( $self, $controller, $action ) = @_;

    my $attr_name = $self->__fetch_attribute_name( $controller );
    my $signature = @{ $self->attributes->{ $attr_name } || [] }[0];
    return 0 unless $signature;
    my @parts = split /\s*,\s*/ => $signature;
        # fetch the signature and return immediately if it's empty.
        # otherwise break it up into it's arguments

    for my $part (@parts) {

        my ( $name, $type )  = CORE::reverse split /\s+/ => $part;
        ( $type, my $param ) = $self->_deconstruct_constraint( $type );
            # break up and store '$Type $name' formatted arguments.
            # 'reverse' is a very bad method name by the way. the
            # constraint deconstruction extracts the parameter, if
            # specified.

        my $constraint =
            ( $type ? $controller->_fetch_constraint( $type ) : undef );
        my $argument   = $CLASS{ argument }->new(
            name        => $name,
            constraint  => $constraint,
            controller  => $controller,
            action      => $self,
            parameter   => $param,
        );
        $argument->initialize;
            # create and initialize the constraint and argument objects.
            # the argument is our most valuable object, as it makes most
            # of the important decisions.

        push @{ $self->_arguments }, $argument;
    }

    return 1;
}

=head2 dispatch

Intercepts the dispatching process to run the values through the
constraints.

=cut

sub dispatch {
    my ( $self, $c ) = ( shift, @_ );

    my %values;
    my @args = @{ $c->req->args };
    my $argument_position = 0;
        # just some initialization for the validation that comes
        # afterwards.

    while (@args) {
        # an argument constraint can handle more than one "physical"
        # arguments. we only proceed as long as there are phys. arguments
        # left. the Args attribute should be concerned about argument
        # numbers, not us.

        my $arg_object = $self->_arguments->[ $argument_position ]
            or last;
        $argument_position++;
        my $takes = $arg_object->takes;
        my $gives = $arg_object->gives;

        my $arg_values = [];
        push @$arg_values, shift @args for 1 .. $takes;
            # the argument list will be reduced by the amount specified
            # in the constraint with 'takes'. multi-value-taking arguments
            # are possible through this.

        my $prepared_values =
            $arg_object->prepare_value( $c, $arg_values );
            # the argument object does the preparation, filterings,
            # validation and autostashings.

        $values{ $arg_object->name } =
            ( (     $takes == 1
                or  $gives == 1
                and ref $prepared_values eq 'ARRAY')
            ? $prepared_values->[0] : $prepared_values );
            # how the value turns out to be presented to the user of the
            # constraint depends on the 'gives' parameter. if it gives
            # only one value, the single value and not the entire array
            # reference is passed.
    }

    local %_ = %values;
    return $self->_original_action->dispatch( @_ ) 
        # the parsed values will be available to the action through
        # the global hash %_.
}

=head1 AUTHOR

Robert 'phaylon' Sedlacek - C<E<lt>phaylon@dunkelheit.atE<gt>>

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;
