package Catalyst::Controller::Constraints::Constraint;
use warnings;
use strict;

use Data::Dumper;
use Moose;

my %CLASS = (
    exception => 'Catalyst::Controller::Constraints::ConstraintFailed',
);

has 'name',         is          => 'rw',
                    isa         => 'Value',
                    required    => 1,
                    ;
has 'inherit_from', is          => 'rw',
                    predicate   => 'inherits',
                    ;
has 'parent',       is          => 'rw',
                    isa         => 'Object',
                    ;
has 'pre_filter',   is          => 'rw',
                    predicate   => 'has_pre_filter',
                    isa         => 'CodeRef',
                    ;
has 'check',        is          => 'rw',
                    predicate   => 'has_check',
                    ;
has 'on_fail',      is          => 'rw',
                    predicate   => 'has_handler',
                    ;
has 'post_filter',  is          => 'rw',
                    predicate   => 'has_post_filter',
                    isa         => 'CodeRef',
                    ;
has 'takes',        is          => 'rw',
                    isa         => 'Int',
                    default     => sub { 1 },
                    ;
has 'gives',        is          => 'rw',
                    isa         => 'Int',
                    ;

=head2 initialize

Initializes parameters and checks validity of them.

=cut

sub initialize {
    my ( $self, $controller ) = @_;

    if ( $self->inherits ) {
        # we instantiate our parent as soon as we're initialized. this
        # also makes debugging a lot easier.

        $self->parent( $controller->_fetch_constraint( 
            $self->inherit_from ) );
    }

    $self->gives( $self->takes ) unless defined $self->gives;
        # we don't want to force people to specify a 'gives' value unless
        # it's different to the number of arguments it 'takes'. The latter
        # is therefore it's default value.

    die "Can't apply regular expression constraint " .
        "to more than one value on '@{[$self->name]}' constraint"
        if $self->takes > 1 and $self->__has_regexp_constraint;
        # for simplicity concerns, it is not possible to specify a regular
        # expression check on a constraint which takes more than one
        # argument. those checks have to be done implicit in a code
        # reference.

    1;
}

=head2 __has_regexp_constraint

Returns true if one of the check values is just a regular expression.
Those can not be applied to multiple values.

=cut

sub __has_regexp_constraint {
    my ( $self ) = @_;
    return 1 if grep { ref $_ eq 'Regexp' } @{ $self->check || [] };
    return 0;
}

=head2 _throw_exception

Throws a validation exception.

=cut

sub _throw_exception {
    my ( $self, $argument, $value, $user_msg ) = @_;

    $CLASS{ exception }->throw(

        error       => sprintf (
            " Invalid value for %s argument '%s' on action '/%s'"
            . ( defined $user_msg ? ": $user_msg" : '' ),
            $self->name,
            $argument->name,
            $argument->action->reverse
        ),  # give a detailed error message for debugging. errors
            # shouldn't be shown on productive systems anyway.

       ( $self->has_handler ?
        (handler    => $self->on_fail) : () ),
            # let's tell the capturer how we'd like to have this
            # validation error handled, if we know.

        user_msg    => $user_msg,
        constraint  => $self->name,
        argument    => $argument->name,
        value       => ( $self->takes == 1 ? $value->[0] : $value ),
            # the name of the constraint, the name of the argument
            # and the failed value are passed too.
    );
}

=head2 prepare_value

Takes the value from the request and returns the finished one.

=cut

sub prepare_value {
    my ( $self, $argument, $c, $value ) = @_;

	if ( $self->has_pre_filter ) {
        local $_ = ( $self->takes == 1 ? $value->[0] : $value );
		#local %_ = (
		#    param       => $argument->parameter,
		#    has_param   => $argument->has_parameter,
		#);
        $value = $self->pre_filter->( 
			$argument->controller, $c, 
			( $self->takes == 1 ? $value->[0] : $value ),
		);
		$value = [ $value ] if $self->takes == 1;
    }

    if ( $self->inherits ) {
        # we pass the validation on to another constraint if we have
        # a parent to inherit from.

        $value = eval {
            $self->parent->prepare_value( $argument, $c, $value ) };

        if ( my $e = Exception::Class->caught( $CLASS{ exception } ) ) {
            # if there was a validation error, we throw a new exception
            # with our handler set, unless of course, the parent constraint
            # already has a handler.

            if ( $self->has_handler and not defined $e->handler ) {
                # set our handler, as we have one and the parent didn't
                # set one.

                ref($e)->throw(
                    handler => $self->on_fail,
                    map {( $_ => $e->$_ )} qw(constraint argument value)
                );
            }
            else {
                $e->rethrow;
            }
        }
        die $@ if $@;
    }

    my $is_valid = 1;
    for my $check (@{ $self->check || [] }) {
        # checks can be either regular expressions or code references.

        if ( ref $check eq 'Regexp' ) {
            $is_valid = 0 unless $value->[0] =~ $check;
        }
        elsif ( ref $check eq 'CODE' ) {
            # a code reference get's the controller and context, like
            # an action, passed as it's arguments before the value.
            # the latter can also be accessed through $_.

            local $_ = ( $self->takes == 1 ? $value->[0] : $value );
			#local %_ = (
			#    param       => $argument->parameter,
			#    has_param   => $argument->has_parameter,
			#);
            local *_ = sub { $self->_throw_exception(
                $argument, $value, shift ) };
            $is_valid = 0 unless
                $check->( $argument->controller, $c, @$value );
        }

        last unless $is_valid;
            # no need to look further if one of our checks failed.
    }

    unless ( $is_valid ) {
        # if the value was invalid, we throw an exception with a
        # suitable error message. if a handler was specified, we
        # throw them along with the exception, so the controller
        # can handle it.

        $self->_throw_exception( $argument, $value );
    }

	if ( $self->has_post_filter ) {
		local $_ = ( $self->takes == 1 ? $value->[0] : $value );
		#local %_ = (
		#    param       => $argument->parameter,
		#    has_param   => $argument->has_parameter,
		#);
        $value = $self->post_filter->( 
			$argument->controller, $c, $value,
			( $self->takes == 1 ? $value->[0] : $value ),
		);
			
		$value = [ $value ] if $self->takes == 1;
    }

    return $value;
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
