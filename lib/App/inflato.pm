package App::inflato;
use strict;
use warnings;
use 5.008_001;
use App::inflato::Skeleton;
use Path::Class;
use File::HomeDir;
use Getopt::Long;
use Pod::Usage;

our $VERSION = '0.01';

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    $self->{argv} = \@_;
    return $self;
}

sub run {
    my $self = shift;

    my ($arg1, @argv) = @{ $self->{argv} };

    my $parser = Getopt::Long::Parser->new(
        config => [ 'require_order' ],
    );

    local @ARGV = @{ $self->{argv} };
    $parser->getoptions(
        'h|help' => \my $help,
        'l|list' => \my $list,
        'e|expand=s' => \my $expand_skel,
        's|save=s'   => \my $save_skel,
    );

    if ($help) {
        $self->help;
    } elsif ($list) {
        $self->list;
    } elsif ($expand_skel) {
        $self->expand($expand_skel, @ARGV);
    } elsif ($save_skel) {
        $self->save($save_skel, @ARGV);
    } elsif (@ARGV >= 2) {
        $self->expand(@ARGV);
    } else {
        pod2usage;
    }
}

sub skeleton {
    my ($self, $skeleton_name, $project_name) = @_;
    return App::inflato::Skeleton->new(
        root => $self->root->subdir('skeleton', $skeleton_name),
        name => $project_name,
    );
}

sub root {
    my $self = shift;
    return $self->{root} ||= $ENV{INFLATO_ROOT} ? dir($ENV{INFLATO_ROOT}) : dir(File::HomeDir->my_home)->subdir('.inflato');
}

sub expand {
    my $self = shift;
    my $skeleton_name = shift or pod2usage;
    my $project_name  = shift or pod2usage;

    local @ARGV = @_;

    GetOptions(
        'd|dir=s' => \my $dir,
        'f|force' => \my $force,
    );

    my $skeleton = $self->skeleton($skeleton_name, $project_name);
    $skeleton->expand(dir => $dir, force => $force);
}

sub save {
    my $self = shift;
    my $skeleton_name = shift or pod2usage;
    my $project_name  = shift or pod2usage;

    local @ARGV = @_;

    GetOptions(
        'd|dir=s' => \my $dir,
        'f|force' => \my $force,
        'with-bootstrap' => \my $with_bootstrap,
    );

    die 'Could not parse args' if @ARGV;

    my $skeleton = $self->skeleton($skeleton_name, $project_name);
    $skeleton->save(dir => $dir, force => $force, with_bootstrap => $with_bootstrap);
}

sub list {
    my $self = shift;
    my $skeleton_dir = $self->root->subdir('skeleton');
    print "List of available skeletons:\n";
    printf " * %s\n", $_->relative($skeleton_dir) for grep { -d $_ } $skeleton_dir->children;
}

sub help {
    my $self = shift;
    pod2usage({ -verbose => 1 });
}

1;

__END__

=head1 NAME

App::inflato -

=head1 SYNOPSIS

  inflato

=head1 DESCRIPTION

App::inflato is

=head1 AUTHOR

motemen E<lt>motemen@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
