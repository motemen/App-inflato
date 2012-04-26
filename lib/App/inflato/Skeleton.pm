package App::inflato::Skeleton;
use strict;
use warnings;
use Text::MicroTemplate;
use Path::Class;
use File::chdir;
use Carp;
use Getopt::Long;

our $DEBUG = $ENV{INFLATO_DEBUG};

our $RESERVED = {
    __PATH__      => sub { $_[0]->escaped_name('/') },
    __NAME__      => sub { $_[0]->escaped_name('-') },
    __NAMESPACE__ => sub { $_[0]->escaped_name('::') },
    __PROP__      => sub { $_[0]->escaped_name('.') },
    __IDENT__     => sub { $_[0]->escaped_name('_') },

    __NAME_LC__   => sub { lc $_[0]->escaped_name('.') },
    __PROP_LC__   => sub { lc $_[0]->escaped_name('-') },
    __IDENT_LC__  => sub { lc $_[0]->escaped_name('_') },
};
our $RESERVED_RE = sprintf '(?:%s)', join '|', map quotemeta, keys %$RESERVED;

sub new {
    my ($class, %args) = @_;
    return bless \%args, $class;
}

sub root { $_[0]->{root} }
sub name { $_[0]->{name} }

sub mt {
    my $self = shift;
    return $self->{mt} ||= Text::MicroTemplate->new(escape_func => undef);
}

our $SKELETON;
sub SKELETON { $SKELETON }

sub expand {
    my ($self, %args) = @_;

    croak qq(skeleton does not exist) unless $self->exists;

    $self->expand_files(%args);
    $self->run_setup;
}

sub expand_files {
    my ($self, %args) = @_;

    my $dir = $args{dir} ? dir($args{dir}) : dir($CWD)->subdir($self->escaped_name('-'));
    $dir->mkpath(1);

    my $files = $self->root->subdir('files');
    $files->recurse(
        callback => sub {
            my $e = shift;
            return unless -f $e;

            # expand path
            my $path = $e->relative($files);
            $path =~ s# ($RESERVED_RE) # $RESERVED->{$1}->($self) #gex;

            my $target = $dir->file($path);
            printf STDERR "%s -> %s", $e->relative($files), $target->relative($CWD);

            my $content = $e->slurp;
               $content =~ s# ($RESERVED_RE) # $RESERVED->{$1}->($self) #gex;
            $self->mt->parse($content);
            $content = do {
                local $_ = local $SKELETON = $self;
                $self->mt->build->();
            };

            if (-e $target) {
                if (!$args{force}) {
                    print STDERR " [exists; skip]\n";
                    return;
                } else {
                    print STDERR " [overwrite]\n";
                }
            } else {
                print STDERR " [create]\n";
            }

            $target->dir->mkpath(1);

            # FIXME overwrite check
            my $fh = $target->openw;
            $fh->print($content);
            $fh->close;
            chmod $e->stat->mode & 07777, $target;
        }
    );
}

sub run_setup {
    my $self = shift;
    my @setup = grep { -x $_ } glob $self->root->file('setup.*');
    foreach my $setup (@setup) {
        print STDERR "running $setup\n";
        local $CWD = dir($CWD)->subdir($self->escaped_name('-'));
        system $setup;
    }
}

sub save {
    my ($self, %args) = @_;

    my $dir = $args{dir} ? dir($args{dir}) : dir($CWD);

    croak qq(skeleton already exists) if $self->exists && !$args{force};

    my $cb = sub {
        my $e = shift;
        return unless -f $e;

        my $reverse = {}; @$reverse{ map { $_->($self) } values %$RESERVED} = keys %$RESERVED;
        my $reverse_re = join '|', map "(\Q$_\E)", keys %$reverse;

        my $path = $e->relative($dir);
        $path =~ s# ($reverse_re) # $reverse->{$1} #gex;

        my $target = $self->root->file('files', $path);
        printf STDERR "%s -> %s\n", $e->relative($dir), $target;

        my $content = $e->slurp;

        # escape special tokens
        $content =~ s/(<\?|\?>)/sprintf q(<?= '%s'.'%s' ?>), split '', $1, 2/ge;
        $content =~ s/($RESERVED_RE)/sprintf q(<?= '%s'.'%s'.'%s' ?>), $1 =~ m<^(..)(.*?)(..)$>/ge;

        $content =~ s# ($reverse_re) # $reverse->{$1} #gex;

        $target->dir->mkpath(1);

        my $fh = $target->openw;
        $fh->print($content);
        $fh->close;
        chmod $e->stat->mode & 07777, $target;
    };

    if (my $git_files = do { local $CWD = $dir; qx(git ls-files -z) }) {
        printf STDERR "using `git ls-files`\n";
        $cb->($dir->file($_)) for split /\0/, $git_files;
    } else {
        $dir->recurse(callback => $cb);
    }

    if ($args{with_bootstrap}) {
        my $bootstrap = $dir->file('bootstrap');
        my $fh = $bootstrap->openw;
        $fh->print("#!/usr/bin/env perl\n");
        $fh->print(scalar file(__FILE__)->slurp);
        $fh->close;
        chmod $bootstrap->stat->mode | 0111, $bootstrap;
        print STDERR "created bootstrap\n";
    }
}

sub exists {
    my $self = shift;
    return -d $self->root;
}

sub escaped_name {
    my ($self, $sep) = @_;
    my $name = escape_filename($self->name, $sep);
       $name =~ s/(?:\Q$sep\E)+/$sep/g if length $sep;
    return $name;
}

# from File::Util

my $DIRSPLIT    = qr/[\x5C\/\:]/;
my $ILLEGAL_CHR = qr/[\x5C\/\|\015\012\r\n\t\013\*\"\?\<\:\>]/;

sub escape_filename {
    my ($file, $escape) = @_;

    $escape = '_' unless defined $escape;

    $file =~ s/$ILLEGAL_CHR/$escape/g;
    $file =~ s/$DIRSPLIT/$escape/g;

    return $file;
}

# bootstrap
if ($0 eq __FILE__) {
    GetOptions(
        'd|dir=s' => \my $dir,
        'f|force' => \my $force,
    );

    my $name = shift or die <<"...";
Usage: $0 [-d dir] Project::Name
...

    my $skeleton = __PACKAGE__->new(
        root => file(__FILE__)->dir,
        name => $name
    );
    $skeleton->expand(dir => $dir, force => $force);
}

1;
