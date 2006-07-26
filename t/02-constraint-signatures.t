use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More tests => 69;

BEGIN { use_ok 'Catalyst::Test', 'TestApp' }

{   #   Single named argument, no constraint
    my $r = request( '/signatures/single/23' );

    ok( $r->is_success, 'Request succeeded' );
    is( $r->content, '23', 'Access to arguments through %_' );
}

{   #   Two arguments are in the signature, and passed
    my $r = request( '/signatures/double/60/33' );

    ok( $r->is_success, 'Request succeeded' );
    is( $r->content, '93', 'Multiple arguments in signature' );
}

{   #   Autostashing
    my $r = request( '/signatures/autostash/bar' );

    ok( $r->is_success, 'Request succeeded' );
    is( $r->content, 'bar', 'Autostashing' );
}

{   #   A simple constraint
    my $r = request( '/signatures/simple/12' );

    ok( $r->is_success, 'Request succeeded' );
    is( $r->content, '12', 'Constraint check ok' );
}

{   #   A simple constraint, failing
    my $r = request( '/signatures/simple/foo' );

    ok( !$r->is_success, 'Constraint failed' );
}

{   #   An array constraint
    my $r = request( '/signatures/perary/23' );

    ok( $r->is_success, 'Request succeeded' );
    is( $r->content, '23', 'Constraint check ok' );
}

{   #   An array constraint, failing
    my $r = request( '/signatures/perary/12' );

    ok( !$r->is_success, 'Constraint failed' );
}

{   #   A detailed constraint
    my $r = request( '/signatures/detail/bar' );

    ok( $r->is_success, 'Request succeeded' );
    is( $r->content, 'bar', 'Constraint check ok' );
}

{   #   A detailed constraint, failing
    my $r = request( '/signatures/detail/baz' );

    ok( !$r->is_success, 'Constraint failed' );
}

{   #   A detailed constraint, failing II
    my $r = request( '/signatures/detail/12' );

    ok( !$r->is_success, 'Constraint failed' );
}

{   #   Look if arguments are still passe dcorrectly
    my $r = request( '/signatures/args/23' );

    ok( $r->is_success, 'Request succeeded' );
    is( $r->content, '23', 'Args passed to action' );
}

{   #   Controller in constraint sub
    my $r = request( '/signatures/ctrl/23' );

    ok( $r->is_success, 'Request succeeded' );
    is( $r->content, 'ok', 'Controller passed to constraint' );
}

{   #   A detailed constraint
    my $r = request( '/signatures/context/23' );

    ok( $r->is_success, 'Request succeeded' );
    is( $r->content, 'ok', 'Context passed to constraint' );
}

{   #   Handle by code reference
    my $r = request( '/signatures/handle_sub/23' );

    ok( $r->is_success, 'Request succeeded, no error' );
    is( $r->content, 'foo:23', 'Constraint handled correctly by callback' );
}

{   #   Handle by relative action name
    my $r = request( '/signatures/handle_act/23' );

    ok( $r->is_success, 'Request succeeded, no error' );
    is( $r->content, 'foo:23', 'Constraint handled correctly by relative handler' );
}

{   #   Handle by absolute action name
    my $r = request( '/signatures/handle_abs/23' );

    ok( $r->is_success, 'Request succeeded, no error' );
    is( $r->content, 'foo:23', 'Constraint handled correctly by absolute handler' );
}

{   #   Inherited constraint, working
    my $r = request( '/signatures/inherited/25' );

    ok( $r->is_success, 'Request succeeded' );
    is( $r->content, '25', 'Constraint handled correctly' );
}

{   #   Inherited constraint, first constraint bites
    my $r = request( '/signatures/inherited/fnord' );

    ok( $r->is_success, 'Request succeeded, no error' );
    is( $r->content, 'Nr:foo:fnord', 'Parent constraint failed' );
}

{   #   Inherited constraint, second constraint bites
    my $r = request( '/signatures/inherited/5' );

    ok( $r->is_success, 'Request succeeded, no error' );
    is( $r->content, 'Inherit:foo:5', 'Inheriting constraint failed' );
}

{   #   An application wide constraint configuration
    my $r = request( '/signatures/appwide/foobar' );

    ok( $r->is_success, 'Request succeeded' );
    is( $r->content, 'foobar', 'Appwide constraint' );
}

{   #   An application wide constraint configuration, failing
    my $r = request( '/signatures/appwide/baz' );

    ok( !$r->is_success, 'Appwide constraint failed' );
}

{   #   A merged application wide constraint configuration
    my $r = request( '/signatures/appwidemerged/foobar' );

    ok( $r->is_success, 'Request succeeded' );
    is( $r->content, 'foobar', 'Appwide constraint, merged' );
}

{   #   A merged application wide constraint configuration, failing
    my $r = request( '/signatures/appwidemerged/baz' );

    ok( $r->is_success, 'Merged appwide constraint, failed and handled' );
    is( $r->content, 'foo:baz', 'Appwide constraint, merged, handled' );
}

{   #   A merged application wide constraint configuration
    my $r = request( '/signatures/appwidemergedor/foobar' );

    ok( $r->is_success, 'Request succeeded' );
    is( $r->content, 'foobar', 'Overridden Appwide constraint, success' );
}

{   #   A merged application wide constraint configuration, failing
    my $r = request( '/signatures/appwidemergedor/baz' );

    ok( $r->is_success, 'Overridden appwide constraint, failed and handled' );
    is( $r->content, 'AppWideMergeOR:foo:baz', 'Overridden constraint, merged, handled' );
}

{   #   Multiple argument slurping
    my $r = request( '/signatures/multi/12/13/14' );

    ok( $r->is_success, 'Request succeeded' );
    is( $r->content, '12;13;14', 'Multiple arguments' );
}

{   #   Filtered and reduced multi-args
    my $r = request( '/signatures/filter/12/11' );

    ok( $r->is_success, 'Request succeeded' );
    is( $r->content, '46:46', 'Filtered and reduced multi-args' );
}

{   #   User Message
    my $r = request( '/signatures/handle_um/23' );

    ok( $r->is_success, 'Request succeeded, fail handled' );
    is( $r->content, 'bad:23', 'Correct User Message' );
}

{   #   Other attribute name for controller
    my $r = request( '/signatures/otherattrname/23' );

    ok( $r->is_success, 'Request succeeded' );
    is( $r->content, 23, 'Correct value received' );
}

{   #   Behaviour correct in chains
    my $r = request( '/signatures/chain/1/2/and/3/4' );

    ok( $r->is_success, 'Request succeeded' );
    is( $r->content, 10, 'Chained' );
}

{   #   Number constraint, succeeding
    my $r = request( '/signatures/is_nr/3.50' );

    ok( $r->is_success, 'Request succeeded' );
    is( $r->content, '3.50', 'Number constraint, valid' );
}

{   #   Number constraint, failing
    my $r = request( '/signatures/is_nr/foo' );

    ok( !$r->is_success, 'Request failed' );
}

{   #   Digit constraint, succeeding
    my $r = request( '/signatures/is_dig/23' );

    ok( $r->is_success, 'Request succeeded' );
    is( $r->content, 23, 'Digit constraint, valid' );
}

{   #   digit constraint, failing
    my $r = request( '/signatures/is_dig/fnord' );

    ok( !$r->is_success, 'Request failed' );
}

{   #   String constraint, succeeding without re
    my $r = request( '/signatures/is_str/foo,23' );

    ok( $r->is_success, 'Request succeeded' );
    is( $r->content, 'foo,23', 'Number constraint, valid' );
}

{   #   String constraint, succeeding with re
    my $r = request( '/signatures/is_str_re/foo' );

    ok( $r->is_success, 'Request succeeded' );
    is( $r->content, 'foo', 'String constraint with RE, valid' );
}

{   #   String constraint with RE, failing
    my $r = request( '/signatures/is_str_re/foo,23' );

    ok( !$r->is_success, 'Request failed' );
}

{   #   Has context object
    my $r = request( '/signatures/has_ctx/foó' );

    ok( $r->is_success, 'Has $_{ctx}' );
}

{   #   Has controller object
    my $r = request( '/signatures/has_ctrl/23' );

    ok( $r->is_success, 'Has $_{ctrl}' );
}



