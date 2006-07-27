=head1 NAME

Catalyst::Controller::Constraints - Constraint Signatures for Controller Actions

=cut

package Catalyst::Controller::Constraints;
use warnings;
use strict;

=head1 VERSION

0.10_02 - Development Release. Production use not recommended yet.

=cut

our $VERSION = '0.10_02';

use NEXT;
use Hash::Merge;
use Scalar::Util;
use base qw(Catalyst::Controller);
use Catalyst::Controller::Constraints::Action;
use Catalyst::Controller::Constraints::Constraint;

__PACKAGE__->mk_accessors(qw( __cached_constraints ));

use Exception::Class
    ( 'Catalyst::Controller::Constraints::ConstraintFailed' 
        => { fields => [qw(
            handler
            argument
            constraint
            value
            user_msg
        )] },
    );

my %CLASS = (
    exception   => 'Catalyst::Controller::Constraints::ConstraintFailed',
    constraint  => 'Catalyst::Controller::Constraints::Constraint',
    action      => 'Catalyst::Controller::Constraints::Action',
);

my %own_constraints = (
	Number => sub { Scalar::Util::looks_like_number( $_ ) },
	Digits => qr/^\d+$/,
	String => sub {
		return 1 unless $_{has_param};
		return $_ =~ $_{param};
	},
);

=head1 SYNOPSIS

  package MyApp::Controller::Foo;
  ...
  use base qw(Catalyst::Controller::Constraints);

  __PACKAGE__->config(
      constraints => {

          #   allow only digits for type 'Integer'
          Integer => qr/^\d+$/,

          #   allow only word chars for type 'Word'
          Word    => sub { /^\w+$/ },

          #   validate user id and inflate to object
          User    => {

              #   check the user id
              check   => sub {
                  my ( $self, $c, $id ) = @_;
                  return $c->is_valid_user_id( $id );
              },

              #   forward to this action if the validation failed
              on_fail => 'invalid_user',

              #   if value is valid, run it through this filter
              #   afterwards
              post_filter => sub {
                  my ( $self, $c, $id ) = @_;
                  $c->fetch_user_by_id( $id );
              },
          }

          #   inheritance
          HighInteger => {
              inherit_from => 'Integer',
              check        => sub { $_ > 22 },
          },

          #   collapse multiple arguments
          MyDate => {

              #   take three integers and return one value
              takes => 3,
              gives => 1,

              #   inflate to a datetime object
              post_filter  => sub {
                  my ( $self, $c, $y, $m, $d ) = @_;
                  DateTime->new(
                      year => $y, month => $m, day => $d );
              }
          }
      }
  );

  #   add two integers, just throws exception on constraint failure
  sub add : Local Args(2) Constraints(Integer a, Integer b) {
      my ( $self, $c ) = @_;
      $c->res->body( $_{a} + $_{b} );
  }

  #   puts the word into the stash, under the key 'foo'
  sub stashword : Local Args(1) Constraints( Word foo* ) { }

  #   user_obj ends as a user object in the stash
  sub view_user : Local Args(1) Constraints( User user_obj* ) { }
  sub invalid_user : Private {
      #   handle invalid userid
  }

  1;

=head1 DESCRIPTION

This controller base class for L<Catalyst> enables you to
apply constraints to your action arguments.

=head1 USAGE

This describes how this controller base class is used. The first thing
that has to be done is to use this instead of C<Catalyst::Controller> as
base class:

  package MyApp::Controller::Foo;
  ...
  use base qw(Catalyst::Controller::Constraints);
  ...

=head2 Defining Constraints

A constraint definition has no needed keys, though the C<check> option is
the most important. It can contain a code reference, a regular expression
reference, or an array reference, containing a list of the former stated:

  MyNumA => { check => qr/^\d+$/ },
  MyNumB => { check => sub { $_ =~ qr/^\d+$/ } },
  MyNumC => { check => [qr/^\d+$/, sub { $_ > 23 }] },

If you just want to supply a check var, you can shortcut that:

  MyNumA => qr/^\d+$/,

As you can see, the arguments value is localized to $_ in your code
reference to keep the definitions more readable. The C<@_> array contains
the controller, the context, and then the constraints arguments, like an
action working with the values.

There are some more options to specify, but let's walk them through step
by step. There's a index of them at the bottom for quick referencing.

In every callback (C<pre_filter>, C<check> and C<post_filter>) you are
provided with the controller and context objects through C<$_{ctrl}> and
C<$_{ctx}>. There's also C<has_param> and C<param>, but we'll be talking
about them later.

There are three possible sources for constraint definitions:

=over 8

=item Shipped constraints

See L</Default Constraints> for information on which constraints are
shipped and ready to use.

=item Constraints defined application wide

Constraints that are placed in your application config under the
C<constraints> key are available to the whole application. Any settings
made under the name of a shipped constraint are merged together with the
shipped config. The application constraints have, of course, priority
over the shipped ones. The merging is especially useful to define app and
per-controller actions for L</Handling Validation Errors>. Here is an 
example:

  package MyApp;
  use Catalyst/ -Debug /;

  __PACKAGE__->config(
    constraints => {
      EvenNumber => {
        check => sub { $_ % 2 },
        on_fail => 'odd_number',
      },
      Int => {
        on_fail => 'not_an_integer',
      },
    },
  );

=item Constraints defined for one controller

These definitions look exactly as those for application wide constraints as
they're introduced above. They differ in that they are only defined for the
current controller, and have priority over shipped and application wide
constraints.

=back

For more control over the error message sent to the user, there is a function
available named C<_()>. A call to C<_( 'foobar' )> will throw a validation
exception that can be handled (See L</Handling Validation Errors>). The
exception will have it's C<user_msg> field set to the passed value. 

=head2 Applying Constraints To Actions

The default constraint attribute name is C<Constraints>, but you can change
that with

  __PACKAGE__->config( constraint_attribute => 'Foo' );

in either your application or your controller. The constraints itself are
just applied to actions through this attribute's parameter, as usual in
Catalyst:

  sub foo : Local Constraint( Int bar, Int baz ) { ... }

You don't have to specify a constraint name. If you'd just do a

  sub foo : Local Constraint( Int bar, baz ) { ... }

then C<baz> wouldn't be checked by any constraint. But you could still
reference it by name. This can also be combined with another convenience
function, autostashing:

  sub foo : Local Constraint( bar*, baz* ) { ... }

would when, for example, called with C<foo/23/17> set the values C<bar>
and C<baz> in the stash to the corresponding values.

The original, unfiltered and unchanged values are passed to the action
through C<@_>, so this controller base class doesn't interfere with
Catalyst's argument passing style at all. However, you can also access
the values through the global C<%_> hash. In the above example,
C<$_{bar}> would be C<23> and C<$_{baz}> would be set to C<17>.

=head2 Handling Validation Errors

Through the C<on_fail> option it's possible to handle a validation error
of C<check>. It's value can be a code reference, treated like an action,
and a relative or absolute private action path. It's arguments will be
The current controller, the context, and the exception object with the
following fields:

=over 8

=item constraint

This is the name of the constraint type, for example, C<Int>.

=item value

The value that didn't pass the inspection.

=item user_msg

Will be set to the value passed to C<_()> if the exception was raised by
this function.

=item argument

The name of the argument that didn't pass the validation.

=back

Here is a complete example:

  package MyApp::Controller::Foo;
  use base qw(Catalyst::Controller::Constraints);

  __PACKAGE__->config(
    constraints => {
      MyInt => {
        check   => qr/^\d+$/,
        on_fail => 'invalid_input',
      },
    }
  );

  sub add : Local Args(2) Constraints( MyInt a, MyInt b ) {
    $_[1]->response->body( $_{a} + $_{b} );
  }

  sub invalid_input : Private {
    my ( $self, $c, $e ) = @_;
    $c->res->body(
      sprintf 'Invalid format of %s for %s: %s',
          $e->constraint,
          $e->argument,
          $e->value,
    );
  }

  1;

=head2 Constraint Inheritance

Sometimes you don't want to override a constraint's behaviour, but rather
add another layer above it. This is where constraint inheritance comes in:

  Word		=> qr/^\w*$/,
  UserName	=> { check => sub { length $_ > 5 }, inherit_from => 'Word' },

=head2 Using And Collapsing Multiple Arguments

Some arguments consist of more than one value, a date for example. You
might want to use three values to create a datetime object. This is a
simple example of this:

  MyDate => {
    takes => 3,
	gives => 1,
	post_filter => sub {
		my ( $self, $c, $y, $m, $d ) = @_;
		DateTime->new( year => $y, month => $m, day => $d );
	}
  }

Note the C<takes> and C<gives> values. The first indicates that this
constraint takes the next three arguments, not just one. This has as
consequence that C<pre_filter>, C<post_filter>, C<check> and the exception
objects C<value> field contain a hashreference. Their return values are
stored in an array reference, too. So a C<pre_filter> that takes more than
one value, but returns only one, results in an arrayref in the next calls
(C<check> and C<post_filter> as value.

The C<gives> value only affects how the value is passed to the dispatched
action. A value of 1 (default is the value of C<takes>, which has a default
of 1) sets the value in C<%_> directly, rather than through an array
reference.

=head2 Pre- And Post-Filters

This is pretty simple. These are callbacks that are called before and after
C<check> is running. They receive the value(s) in C<$_> and starting with
index 2 in C<@_>. Their return value is used as new value for the next
calls.

=head2 Constraint Parameters

To prevent the need for many equal constraints, it is possible to pass a
parameter to them. Usage examples would be Model constraints, that check
for existance, permission and load the row from the database. A parameter
can be passed to a constraint with C<[...]> directly after its name:

  sub foo : Local Constraint( Model[Category] cat* ) { ... }

(This would also autostash the resulting object, due to C<*>.)

Access to the parameter is provided through the global C<%_> hashes key
C<param>, read: C<$_{param}>. To find out if a parameter was actually
provided, you can check C<$_{has_param}>.

=head2 Default Constraints

To set the C<on_fail> handler for shipped constraints, override those
parameter's option in your controller or application config.

=over 8

=item Digits

Checks if the value consists only of digits, this means it's just a
regular expression checking for C<^\d+$>.

=item Number

Utilises L<Scalar::Util>'s C<looks_like_number> function to check if the
value, well, looks like a number.

=item String[$re]

Takes a regular expression parameter and validates the string against it.
E.g.

  sub foo : Local Constraints( String[^\w+$] bar ) { }

=back

=head1 CONSTRAINT OPTION REFERENCE

=over 8

=item takes

Specifies how many arguments are used as input.

=item gives

Specifies how many values are going to arrive at the action.

=item pre_filter

Callback, runs before C<check>. Value is afterwards what was returned.

=item check

Validation check. Return true or false, or throw a validation exception
with a C<user_msg> through C<_()>.

=item post_filter

Like C<pre_filter>, but after check.

=back

=head1 METHODS

=head2 create_action

Overrides L<Catalyst::Controller>'s C<create_action> to wrap the original
one in a L<Catalyst::Controller::Constraints::Action> proxy object.

=head2 _fetch_constraint

Returns a constraint object by constraint name. If this type was already created,
a cached version is returned.

=head2 _ACTION

Does the handling of the validation exceptions.

=cut

=head1 SEE ALSO

L<http://www.catalystframework.org/>,

=head1 AUTHOR

Robert 'phaylon' Sedlacek - C<E<lt>phaylon@dunkelheit.atE<gt>>

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

sub create_action {
    my $self   = shift;
    my $action = $self->NEXT::create_action( @_ );
    return $CLASS{ action }->new( $self, $action );
}

sub _fetch_constraint {
    my ( $self, $name ) = @_;
    $self->__cached_constraints({}) unless $self->__cached_constraints;

    my $cached = $self->__cached_constraints->{ $name };
    return $cached if $cached;
        # check for a cached version of this constraint. Most constraints
        # will be used more than once, so caching should be inherent.

	my $own_profile = $own_constraints{ $name };
    my $app_profile =
        $self->{ application }->config->{ constraints }{ $name };
    my $con_profile = $self->config->{ constraints }{ $name };
        # fetch constraint profiles from the application and ourself.
        # the 'application' hash ref is used as in catalyst itself.
        # <blame>mst said I can use it</blame>

    die "Unable to find a constraint named '$name'"
        unless grep { defined } $con_profile, $app_profile, $own_profile;
        # we need a profile for this, an empty profile will do, but is
        # rather useless. left in for debugging purposes anyway, so the
        # config can just be commented out, with inheritance staying
        # intact.

    for ($con_profile, $app_profile, $own_profile) {
        # assure both are hash references, if they're set. if the value
        # is not a hash, it is assumed to be a shortcut to the check
        # value.

        next unless defined $_;
        $_ = { check => $_ } unless ref $_ eq 'HASH';
    }

    my $profile = Hash::Merge::merge( 
        ( $con_profile || {} ),
		Hash::Merge::merge(
			( $app_profile || {} ),
			( $own_profile || {} ),
		),
    );  # merge the two profiles together, if both are hash references.
        # either way, prefer the controller profile.

    my %data = ( name => $name );
    $data{ $_ } = $profile->{ $_ } for keys %$profile;
        # transfer the profile values one to one into the data hash

    if ( defined $data{ check } ) {
        # the check var can need a bit more care. we check it's
        # value and store finally an arrayref, if it's one of our accepted
        # shortcut values.

        if ( ref $data{ check } eq 'Regexp' or
             ref $data{ check } eq 'CODE'
        ) {
            $data{ check } = [ $data{ check } ];
        }

        unless ( ref $data{ check } eq 'ARRAY' ) {
            # the value is not an array reference, this also means we were
            # unable to find a value to accept. so we bark.

            die "Invalid 'check' value in profile for '$name' constraint";
        }

        for (@{ $data{ check } }) {
            # we also check every value in the check array, since it could
            # be that it already was one. this only happens once at startup
            # so it shouldn't be a real impact.

            die "Invalid 'check' value in profile for '$name' constraint"
                unless ref $_ eq 'Regexp'
                    or ref $_ eq 'CODE';
        }
    }

    my $constraint = $CLASS{ constraint }->new( %data );
    $constraint->initialize( $self );
    $self->__cached_constraints->{ $name } = $constraint;
        # create the constraint object and store it in our cache
        # for later requests

    return $constraint;
}

sub _ACTION : Private {
    my ( $self, $c ) = ( shift, @_ );
    my @returned = eval { $self->SUPER::_ACTION( @_ ) };
        # continue to the original action call. notice that NEXT won't
        # work here.

    if ( my $e = Exception::Class->caught( $CLASS{ exception } ) ) {
        # if a validity exception was thrown, we try to handle it, if
        # we can. if we don't, we just rethrow it. code references will
        # be executed just as an action, and everything else is regarded
        # as an action address, usable by 'detach'.

        if ( not defined $e->handler ) {
            $e->rethrow;
        }
        elsif ( ref $e->handler eq 'CODE' ) {
            return $e->handler->( $self, $c, $e );
        }
        elsif ( not ref $e->handler ) {
            $c->detach( $e->handler, [ $e ] );
        }
    }
    die $@ if $@;

    return @returned;
}


1;
