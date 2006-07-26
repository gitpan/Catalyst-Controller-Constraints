use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More tests => 8;

BEGIN { use_ok 'Catalyst::Test', 'TestApp' }

ok( request( '/' )->is_success, 'General request succeeds' );

{   #   Basic dispatching to constraint subclass
    my $r = request( '/basic' );

    ok( $r->is_success, 'Request to constraint subclass succeeds' );
    is( $r->content, 'basic index', 'Request gave correct output' );
}

{   #   Class of the generated actions must be our delegator
    my $r = request( '/basic/class' );

    ok( $r->is_success, 'Request succeeded' );
    is( $r->content, 'Catalyst::Controller::Constraints::Action',
        'Action class is our wrapper' );
}

{   #   Checking if uri_for is still happy
    my $r = request( '/basic/uri_for' );

    ok( $r->is_success, 'Request succeeded' );
    is( $r->content, 'http://localhost/basic/uri_for/23',
        'uri_for is still happy' );
}
