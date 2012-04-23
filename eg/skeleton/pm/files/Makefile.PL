use inc::Module::Install;

name '__NAME__';
all_from 'lib/__PATH__.pm';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';

auto_set_repository;
auto_include;

readme_from 'lib/__PATH__.pm';

WriteAll;
