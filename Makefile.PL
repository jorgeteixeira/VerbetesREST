use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'VerbetesREST',
    VERSION_FROM      => 'lib/VerbetesREST.pm', # finds $VERSION
    PREREQ_PM         => { 'DBI', 'JSON', 'XML::Simple', 'Encode', 'CGI'}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/VerbetesREST.pm', # retrieve abstract from module
       AUTHOR         => 'Jorge Teixeira <jft@fe.up.pt>') : ()),
);
