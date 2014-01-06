# ABSTRACT: Basic standalone HTTP server for Dancer2

package Dancer2::Core::Server::Standalone;
{
  $Dancer2::Core::Server::Standalone::VERSION = '0.11';
}

use Moo;
use Dancer2::Core::Types;
with 'Dancer2::Core::Role::Server';
use parent 'HTTP::Server::Simple::PSGI';


sub _build_name {'Standalone'}


has backend => (
    is      => 'ro',
    isa     => InstanceOf ['HTTP::Server::Simple::PSGI'],
    lazy    => 1,
    builder => '_build_backend',
);

sub _build_backend {
    my $self = shift;
    $self->app( $self->psgi_app );
    return $self;
}


sub start {
    my $self = shift;

    $self->is_daemon
      ? $self->backend->background()
      : $self->backend->run();

}

sub print_banner {
    my $self = shift;
    my $pid  = $$;      #Todo:how to get background pid?

    # we only print the info if we need to
    Dancer2->runner->config->{'startup_info'} or return;

    # bare minimum
    print STDERR ">> Dancer2 v$Dancer2::VERSION server $pid listening "
      . 'on http://'
      . $self->host . ':'
      . $self->port . "\n";

    # all loaded plugins
    foreach my $module ( grep { $_ =~ m{^Dancer2/Plugin/} } keys %INC ) {
        $module =~ s{/}{::}g;     # change / to ::
        $module =~ s{\.pm$}{};    # remove .pm at the end
        my $version = $module->VERSION;

        defined $version or $version = 'no version number defined';
        print STDERR ">> $module ($version)\n";
    }

}
1;

__END__

=pod

=head1 NAME

Dancer2::Core::Server::Standalone - Basic standalone HTTP server for Dancer2

=head1 VERSION

version 0.11

=head1 DESCRIPTION

This is a server implementation for a stand-alone server. It contains all the
code to start an L<HTTP::Server::Simple::PSGI> server and handle the requests.

This class consumes the role L<Dancer2::Core::Server::Standalone>.

=head1 ATTRIBUTES

=head2 backend

A L<HTTP::Server::Simple::PSGI> server.

=head1 METHODS

=head2 name

The server's name: B<Standalone>.

=head2 start

Starts the server.

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
