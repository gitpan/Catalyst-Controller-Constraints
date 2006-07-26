package TestApp::Controller::Signatures;
use warnings;
use strict;

use base qw(Catalyst::Controller::Constraints);

#__PACKAGE__->action_constraints({
#    Nr => sub { /^\d+$/ },
#});

__PACKAGE__->config(
    constraints => {
        Nr      => sub { /^\d+$/ },
        Woot    => [sub { /^\d+$/ }, sub { $_ == 23 }],
        Detail  => {
            check => [qr/^\D*$/, sub { $_ eq 'bar' }],
        },
        SubHandled => {
            check   => sub { 0 },
            on_fail => sub { $_[1]->res->body( join ':', $_[2]->argument, $_[2]->value ) },
        },
        ActHandled => {
            check   => sub { 0 },
            on_fail => 'fail_handler',
        },
        AbsActHandled => {
            check   => sub { 0 },
            on_fail => '/signatures/fail_handler',
        },
        Inherit => {
            inherit_from => 'Nr',
            check        => sub { $_ > 23 },
            on_fail      => 'fail_handler_detailed',
        },
        Context => sub { $_[1]->isa( 'TestApp' ) },
        Ctrl    => sub { $_[0]->isa( 'Catalyst::Controller' ) },
        AppWideMerge => {
            on_fail => 'fail_handler',
        },
        AppWideMergeOR => {
            on_fail => 'fail_handler_detailed',
        },
        Multi => {
            takes   => 3,
            check   => sub { grep { $_ >= 5 } @$_ },
            on_fail => 'fail_handler',
        },
        Filter => {
            takes       => 2,
            pre_filter  => sub { [ $_->[0] + $_->[1] ] },
            check       => sub { $_->[0] == 23 },
            post_filter => sub { $_->[0] * 2 },
            gives       => 1,
        },
        PCRE => {
            check       => sub { $_ =~ $_{param} },
            on_fail     => sub {
                my ( $self, $c, $e ) = @_;
                $c->res->body( $_{param} . '|' . $e->value );
            },
        },
		UserMsg => {
			check		=> sub { _( 'bad:' . $_  ) },
			on_fail		=> 'fail_user_msg',
		},
		AddUp   => {
			takes => 2,
			gives => 1,
			post_filter => sub { $_->[0] + $_->[1] },
		},
		HasCTX  => sub { $_{ctx}->isa( 'TestApp' ) },
		HasCTRL => sub { $_{ctrl}->isa( 'Catalyst::Controller::Constraints' ) },
    },
);

sub has_ctx : Chained PathPart('signatures/has_ctx') Constraints( HasCTX foo ) { }
sub has_ctrl : Chained PathPart('signatures/has_ctrl') Constraints( HasCTRL foo ) { }

sub is_dig : Chained PathPart('signatures/is_dig') Constraints( Digits foo ) {
	my ( $self, $c ) = @_;
	$c->res->body( $_{foo} );
}

sub is_nr  : Chained PathPart('signatures/is_nr')  Constraints( Number foo ) {
	my ( $self, $c ) = @_;
	$c->res->body( $_{foo} );
}

sub is_str : Chained PathPart('signatures/is_str') Constraints( String foo ) {
	my ( $self, $c ) = @_;
	$c->res->body( $_{foo} );
}

sub is_str_re : Chained PathPart('signatures/is_str_re') Constraints( String[^\w+$] foo ) {
	my ( $self, $c ) = @_;
	$c->res->body( $_{foo} );
}

sub ca : Chained PathPart('signatures/chain') CaptureArgs(2) Constraints( AddUp foo* ) { }
sub cb : Chained('ca') PathPart('and') Args(2) Constraints( AddUp bar* ) {
	my ( $self, $c ) = @_;
	$c->res->body( $c->stash->{foo} + $c->stash->{bar} );
}

sub handle_sub : Chained PathPart('signatures/handle_sub') Constraints( SubHandled foo ) { }
sub handle_act : Chained PathPart('signatures/handle_act') Constraints( ActHandled foo ) { }
sub handle_abs : Chained PathPart('signatures/handle_abs') Constraints( AbsActHandled foo ) { }

sub handle_um  : Chained PathPart('signatures/handle_um')  Constraints( UserMsg foo ) { }

sub fail_user_msg : Private {
	my ( $self, $c, $e ) = @_;
	$c->res->body( $e->user_msg );
}

sub fail_handler : Private {
    my ( $self, $c, $exception ) = @_;
    $c->res->body( join( ':', $exception->argument, $exception->value ) );
}

sub fail_handler_detailed : Private {
    my ( $self, $c, $exception ) = @_;
    $c->res->body( join ':', map { $exception->$_ } qw(constraint argument value) );
}

sub para : Chained PathPart('signatures/param') Constraints( PCRE[^\d+$] foo* ) {
    my ( $self, $c ) = @_;
    $c->res->body( $c->stash->{foo} . ':' . $_{foo} );
}

sub filter : Chained PathPart('signatures/filter') Constraints( Filter foo* ) {
    my ( $self, $c ) = @_;
    $c->res->body( $c->stash->{foo} . ':' . $_{foo} );
}

sub multi : Chained PathPart('signatures/multi') Constraints( Multi foo ) {
    my ( $self, $c ) = @_;
    $c->res->body( join ';', @{ $_{foo} } );
}

sub awmor : Chained PathPart('signatures/appwidemergedor') Constraints( AppWideMergeOR foo ) {
    my ( $self, $c ) = @_;
    $c->res->body( $_{foo} );
}

sub awm : Chained PathPart('signatures/appwidemerged') Constraints( AppWideMerge foo ) {
    my ( $self, $c ) = @_;
    $c->res->body( $_{foo} );
}

sub appwide : Chained PathPart('signatures/appwide') Constraints( AppWide foo ) {
    my ( $self, $c ) = @_;
    $c->res->body( $_{foo} );
}

sub inherited : Chained PathPart('signatures/inherited') Constraints( Inherit foo ) {
    my ( $self, $c, $foo ) = @_;
    $c->res->body( $foo );
}

sub args    : Chained PathPart('signatures/args') Constraints( foo ) {
    my ( $self, $c, $foo ) = @_;
    $c->res->body( $foo );
}

sub context : Chained PathPart('signatures/context') Constraints( Context foo ) {
    my ( $self, $c ) = @_;
    $c->res->body('ok');
}

sub ctrl   : Chained PathPart('signatures/ctrl') Constraints( Ctrl foo ) {
    my ( $self, $c ) = @_;
    $c->res->body('ok');
}

sub single : Chained PathPart('signatures/single') Constraints( foo ) {
    my ( $self, $c ) = @_;
    $c->res->body( $_{foo} );
}

sub double : Chained PathPart('signatures/double') Args(2) Constraints( foo, bar ) {
    my ( $self, $c ) = @_;
    $c->res->body( $_{foo} + $_{bar} );
}

sub autostash : Chained PathPart('signatures/autostash') Args(1) Constraints( foo* ) {
    my ( $self, $c ) = @_;
    $c->res->body( $c->stash->{ foo } );
}

sub simple : Chained PathPart('signatures/simple') Args(1) Constraints( Nr foo ) {
    my ( $self, $c ) = @_;
    $c->res->body( $_{foo} );
}

sub perary : Chained PathPart('signatures/perary') Args(1) Constraints( Woot foo ) {
    my ( $self, $c ) = @_;
    $c->res->body( $_{foo} );
}

sub detail : Chained PathPart('signatures/detail') Args(1) Constraints( Detail foo* ) {
    my ( $self, $c ) = @_;
    $c->res->body( $c->stash->{foo} );
}

1;
