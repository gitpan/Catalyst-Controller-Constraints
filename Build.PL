use Module::Build;

my $build = Module::Build->new(
    module_name         => 'Catalyst::Controller::Constraints',
    license             => 'perl',
    dist_author         => q{Robert 'phaylon' Sedlacek (phaylon@dunkelheit.at)},
    create_readme       => 1,
    dist_abstract       => 'Constraint Signatures for Controller Actions',
    dist_version_from   => 'lib/Catalyst/Controller/Constraints.pm',
    requires            => {
        'Catalyst::Runtime'     => '5.70',
        'Moose'                 => '0.05',
        'Class::Delegator'      => 0,
        'Exception::Class'      => 0,
        'Hash::Merge'           => 0,
        'Scalar::Util'          => 0,
        'Test::More'            => 0,
    },
);
$build->create_build_script;

