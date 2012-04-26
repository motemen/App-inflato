use 5.002;
use inc::Module::Install;

BEGIN {
    my @lacking;
    local @INC = ('inc', @INC);
    for (qw(
        Module::Install::AuthorTests
        Module::Install::Repository
        Module::Install::ReadmeMarkdownFromPod
    )) {
        next if eval "require $_";
        warn;
        push @lacking, $_;
    }
    if (@lacking) {
        print "# some modules are lacking:\n";
        print "# run `$^X $0 | cpanm`\n";
        print "$_\n" for @lacking;
        exit 1;
    }
}

name 'App-inflato';
all_from 'lib/App/inflato.pm';

requires 'Class::Accessor::Lite';

requires 'File::HomeDir';
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

readme_markdown_from 'bin/inflato';

if ($Module::Install::AUTHOR) {
    require File::Copy;
    File::Copy::mv('README.mkdn', 'README.md');
}

WriteAll;
