# NAME

inflato - Project skeleton generator

# SYNOPSIS

    inflato pm My::Module

    inflato --save myapp Existing::My::App --dir ~/project/Existing-My-App

    inflato --list

# OPTIONS AND ARGUMENTS

## inflato \[--expand\] _skeleton_ _Project::Name_ \[--dir=_dir_\]

Expands _skeleton_ for project named _Project::Name_ into a new directory under _dir_.

- \--dir=_dir_

Directory to expand project files into. Defaults to "./_Project-Name_".

## inflato --save _skeleton_ _Project::Name_ \[--dir=_dir_\]

Creates a new skeleton _skeleton_ from an existing project _Project::Name_, whose root is _dir_.

- \--dir=_dir_

Directory to create skeleton from. Defaults to ".".

## inflato --list

Prints defined skeleton.