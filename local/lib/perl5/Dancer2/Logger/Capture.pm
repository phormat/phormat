# ABSTRACT: Capture dancer logs

package Dancer2::Logger::Capture;
{
  $Dancer2::Logger::Capture::VERSION = '0.11';
}
use Moo;
use Dancer2::Logger::Capture::Trap;

with 'Dancer2::Core::Role::Logger';


has trapper => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_trapper',
);

sub _build_trapper { Dancer2::Logger::Capture::Trap->new }

sub log {
    my ( $self, $level, $message ) = @_;

    $self->trapper->store( $level => $message );
    return;
}

1;

__END__

=pod

=head1 NAME

Dancer2::Logger::Capture - Capture dancer logs

=head1 VERSION

version 0.11

=head1 SYNOPSIS

The basics:

    set logger => "capture";

    my $trap = dancer_app->engine('logger')->trapper;
    my $logs = $trap->read;

A worked-out real-world example:

    use Test::More tests => 2;
    use Dancer2;

    set logger => 'capture';

    warning "Danger!  Warning!";
    debug   "I like pie.";

    my $trap = dancer_app->engine('logger')->trapper;

    is_deeply $trap->read, [
        { level => "warning", message => "Danger!  Warning!" },
        { level => "debug",   message => "I like pie.", }
    ];

    # each call to read cleans the trap
    is_deeply $trap->read, [];

=head1 DESCRIPTION

This is a logger class for L<Dancer2> which captures all logs to an object.

It's primary purpose is for testing.

=head1 METHODS

=head2 trap

Returns the L<Dancer2::Logger::Capture::Trap> object used to capture
and read logs.

=head1 SEE ALSO

L<Dancer2::Core::Role::Logger>, L<Dancer2::Logger::Capture::Trap>

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut