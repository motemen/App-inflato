package App::inflato::Skeleton;
use strict;
use warnings;
use Text::MicroTemplate;
use Path::Class;
use File::chdir;
use File::Util qw(escape_filename);
use Class::Accessor::Lite (
    new => 1,
    ro  => [ 'root', 'name' ],
);

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

sub mt {
    my $self = shift;
    return $self->{mt} ||= Text::MicroTemplate->new(escape_func => undef);
}

our $SKELETON;
sub SKELETON { $SKELETON }

sub expand {
    my $self = shift;
    $self->expand_files;
}

sub expand_files {
    my $self = shift;

    my $base = dir($CWD)->subdir($self->escaped_name('-'));
    $base->mkpath(1);

    my $files = $self->root->subdir('files');
    $files->recurse(
        callback => sub {
            my $e = shift;
            return unless -f $e;

            # expand path
            my $path = $e->relative($files);
            $path =~ s# ($RESERVED_RE) # $RESERVED->{$1}->($self) #gex;

            printf STDERR "%s -> %s\n", $e->relative($files), $path if $DEBUG;

            my $target = $base->file($path);
            $target->dir->mkpath(1);

            my $content = $e->slurp;
               $content =~ s# ($RESERVED_RE) # $RESERVED->{$1}->($self) #gex;
            $self->mt->parse($content);

            # TODO chmod
            my $fh = $target->openw;
            $fh->print(do {
                local $_ = local $SKELETON = $self;
                $self->mt->build->();
            });
        }
    );
}

sub save {
    my ($self, %args) = @_;
    my $source = delete $args{source};

    my $cb = sub {
        my $e = shift;
        return unless -f $e;

        my $reverse = {}; @$reverse{ map { $_->($self) } values %$RESERVED} = keys %$RESERVED;
        my $reverse_re = join '|', map "(\Q$_\E)", keys %$reverse;

        my $path = $e->relative($source);
        $path =~ s# ($reverse_re) # $reverse->{$1} #gex;

        printf STDERR "%s -> %s\n", $e->relative($source), $path if $DEBUG;

        my $target = $self->root->file('files', $path);
        $target->dir->mkpath(1);

        my $content = $e->slurp;

        # escape special tokens
        $content =~ s/(<\?|\?>)/sprintf q(<?= '%s'.'%s' ?>), split '', $1, 2/ge;
        $content =~ s/($RESERVED_RE)/sprintf q(<?= '%s'.'%s'.'%s' ?>), $1 =~ m<^(..)(.*?)(..)$>/ge;

        $content =~ s# ($reverse_re) # $reverse->{$1} #gex;

        my $fh = $target->openw;
        $fh->print($content);
    };

    if (my $git_files = do { local $CWD = $source; qx(git ls-files -z) }) {
        printf STDERR "using `git ls-files`\n" if $DEBUG;
        $cb->($source->file($_)) for split /\0/, $git_files;
    } else {
        $source->recurse(callback => $cb);
    }
}

sub escaped_name {
    my ($self, $sep) = @_;
    my $name = escape_filename($self->name, $sep);
       $name =~ s/(?:\Q$sep\E)+/$sep/g if length $sep;
    return $name;
}

1;
