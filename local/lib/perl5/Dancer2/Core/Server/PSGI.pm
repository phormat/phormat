# ABSTRACT: Dummy class for passing the PSGI app to a PSGI server

package Dancer2::Core::Server::PSGI;
{
  $Dancer2::Core::Server::PSGI::VERSION = '0.11';
}
use Moo;
use Carp;
use Plack::Request;

with 'Dancer2::Core::Role::Server';


sub start {
    my ($self) = @_;
    $self->psgi_app;
}

sub _build_name {'PSGI'}

1;

__END__

=pod

=head1 NAME

Dancer2::Core::Server::PSGI - Dummy class for passing the PSGI app to a PSGI server

=head1 VERSION

version 0.11

=head1 DESCRIPTION

When used as a server, this class just return the PSGI application.

=head1 METHODS

=head2 name

The server's name: B<PSGI>.

=head2 start

Return the PSGI application

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
