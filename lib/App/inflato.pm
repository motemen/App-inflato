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

    local @ARGV = @{ $self->{argv} };
    pod2usage unless @ARGV;

    if ($ARGV[0] =~ /^(?:--help|-h)$/) {
        pod2usage({ -verbose => 1 });
    } elsif ($ARGV[0] =~ /^(?:--save|-s)$/) {
        # save
        shift @ARGV; # discard '-s'

        my $skeleton_name = shift @ARGV or pod2usage;
        my $source_dir    = shift @ARGV or pod2usage;

        GetOptions(
            'hint=s' => \my $hint_name,
        );

        pod2usage unless $hint_name;

        my $skeleton = App::inflato::Skeleton->new(
            root => $self->root->subdir('skeleton', $skeleton_name),
            name => $hint_name
        );
        $skeleton->save(source => dir($source_dir));
    } elsif (($ARGV[0] =~ /^(?:--expand|-x)$/ && shift @ARGV) || $ARGV[0] !~ /^-/) {
        # expand
        my $skeleton_name = shift @ARGV or pod2usage;
        my $name          = shift @ARGV or pod2usage;

        my $skeleton = App::inflato::Skeleton->new(
            root => $self->root->subdir('skeleton', $skeleton_name),
            name => $name,
        );
        $skeleton->expand;
    } else {
        pod2usage;
    }
}

sub root {
    my $self = shift;
    return $self->{root} ||= dir(File::HomeDir->my_home)->subdir('.inflato');
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
