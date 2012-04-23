use inc::Module::Install;

name 'App-inflato';
all_from 'lib/App/inflato.pm';

# requires '';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';

auto_set_repository;
auto_include;

readme_from 'bin/inflato';

WriteAll;
