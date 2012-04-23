use inc::Module::Install;

name 'App-inflato';
all_from 'lib/App/inflato.pm';

requires 'Class::Accessor::Lite';

requires 'File::HomeDir';
requires 'File::Util';
requires 'File::chdir';
requires 'Path::Class';

requires 'Text::MicroTemplate';

requires 'Getopt::Long';
requires 'Pod::Usage';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';

auto_set_repository;
auto_include;

readme_from 'bin/inflato';

WriteAll;
