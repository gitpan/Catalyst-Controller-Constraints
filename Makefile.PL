

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Catalyst::Controller::Constraints',
    VERSION_FROM => 'lib/Catalyst/Controller/Constraints.pm',
    AUTHOR       => q{Robert 'phaylon' Sedlacek (phaylon@dunkelheit.at)},
    ABSTRACT     => 'Constraint Signatures for Controller Actions',
    PREREQ_PM    => {
                     'Test::More'			=> 0,
					 'Hash::Merge'			=> 0,
					 'Class::Delegator'		=> 0,
					 'Catalyst::Runtime'	=> 5.70,
					 'Moose'				=> 0.05,
					 'Exception::Class'		=> 0,
					 'Scalar::Util'			=> 0,
                    },
);
