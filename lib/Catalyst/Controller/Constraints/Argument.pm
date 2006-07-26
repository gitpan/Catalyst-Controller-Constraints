package Catalyst::Controller::Constraints::Argument;
use warnings;
use strict;

use Moose;

has 'name',         is          => 'rw',
                    isa         => 'Value',
                    required    => 1,
                    ;
has 'constraint',   is          => 'rw',
                    isa         => 'Object',
                    predicate   => 'has_constraint',
                    ;
has 'action',       is          => 'rw',
                    isa         => 'Object',
                    weak_ref    => 1,
                    required    => 1,
                    ;
has 'controller',   is          => 'rw',
                    isa         => 'Object',
                    weak_ref    => 1,
                    required    => 1,
                    ;
has 'autostash',    is          => 'rw',
                    isa         => 'Bool',
                    default     => sub { 0 },
                    ;
has 'parameter',    is          => 'rw',
                    isa         => 'Value',
                    predicate   => 'has_parameter',
                    ;

=head1 METHODS

=head2 takes

Delegates to C<$self-E<gt>constraint-E<gt>takes>.

=cut

sub takes {
    my ( $self ) = @_;
    return( $self->has_constraint ? $self->constraint->takes : 1 );
}

=head2 gives

Delegates to C<$self-E<gt>constraint-E<gt>gives>.

=cut

sub gives {
    my ( $self ) = @_;
    return( $self->has_constraint ? $self->constraint->gives : 1 );
}

=head2 initialize

Initializes constraints and parameters.

=cut

sub initialize {
    my ( $self ) = @_;

    my $name = $self->name;
    if ( $name =~ s/\*$// ) {
        # arguments that end in a '*' will be autostashed on
        # preparation.

        $self->autostash(1);
        $self->name( $name );
    }

    1;
}

=head2 prepare_value

Takes value from request and returns the finished one.

=cut

sub prepare_value {
    my ( $self, $c, $value ) = @_;

    if ( $self->has_constraint ) {
        # if a constraint was specified with this argument, we run it.
        # this may throw an exception and end this request's journey.
        # a possible parameter is also passed through %_.

        local %_ = (
            param       => $self->parameter,
            has_param   => $self->has_parameter,
			ctx			=> $c,
			ctrl		=> $self->controller,
        );
        $value = $self->constraint->prepare_value( $self, $c, $value );
    }

    if ( $self->autostash ) {
        # when we're supposed to autostash the value, we just do that.
        # depending on the values of 'takes' and 'gives' we're setting
        # just one value, not the array reference.

        $c->stash->{ $self->name } = (
            (       $self->gives == 1
              and   ref $value eq 'ARRAY' ) ? $value->[0] : $value );
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
