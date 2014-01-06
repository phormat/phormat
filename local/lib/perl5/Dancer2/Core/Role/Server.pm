# ABSTRACT: Role for Server classes
package Dancer2::Core::Role::Server;
{
  $Dancer2::Core::Role::Server::VERSION = '0.11';
}
use Moo::Role;

use Carp 'croak';
use File::Spec;

use Dancer2::Core::Types;
use Dancer2::Core::App;
use Dancer2::Core::Dispatcher;
use Dancer2::Core::Response;
use Dancer2::Core::Request;
use Dancer2::Core::Context;

requires '_build_name';

has name => (
    is      => 'ro',
    lazy    => 1,
    builder => 1,
);

has host => (
    is       => 'rw',
    isa      => Str,
    required => 1,
);

has port => (
    is       => 'rw',
    isa      => Num,
    required => 1,
);

has is_daemon => (
    is  => 'rw',
    isa => Bool,
);

has apps => (
    is      => 'ro',
    isa     => ArrayRef,
    default => sub { [] },
);

has dispatcher => (
    is      => 'rw',
    isa     => InstanceOf ['Dancer2::Core::Dispatcher'],
    lazy    => 1,
    builder => '_build_dispatcher',
);

has postponed_hooks => (
    is      => 'rw',
    isa     => HashRef,
    default => sub { {} },
);

sub _build_dispatcher {
    my ($self) = @_;
    my $d = Dancer2::Core::Dispatcher->new();
    $d->apps( $self->apps );
    return $d;
}

# our PSGI application
sub psgi_app {
    my ($self) = @_;
    sub {
        my ($env) = @_;
        my $app;

        eval { $app = $self->dispatcher->dispatch($env)->to_psgi; };

        if ($@) {
            return [
                500,
                [ 'Content-Type' => 'text/plain' ],
                ["Internal Server Error\n\n$@"],
            ];
        }
        return $app;
    };
}

sub register_application {
    my ( $self, $app ) = @_;
    push @{ $self->apps }, $app;
    $app->server($self);

    # add postponed hooks to our app-global copy
    $self->add_postponed_hooks( $app->postponed_hooks );
}

sub add_postponed_hooks {
    my $self  = shift;
    my $hooks = shift;

    $self->postponed_hooks( {
        %{ $self->postponed_hooks },
        %{ $hooks },
    } );
}

1;

__END__

=pod

=head1 NAME

Dancer2::Core::Role::Server - Role for Server classes

=head1 VERSION

version 0.11

=head1 DESCRIPTION

This role defines what servers need to implement and provide some helpful
attributes and methods for server implementations.

This role requires implementations that consume it to provide a C<name>
subroutine.

=head1 ATTRIBUTES

=head2 host

Hostname to which the server will bind.

B<Required>.

=head2 port

Port number to which the server will bind.

B<Required>.

=head2 is_daemon

Boolean for whether the server should daemonize.

=head2 apps

An arrayref to hold Dancer2 applications.

=head2 dispatcher

A read/write attribute which holds the L<Dancer2::Core::Dispatcher> object, to
dispatch an incoming request to the appropriate route.

It has a lazy builder that creates a new dispatcher with the server's apps.

=head2 postponed_hooks

Postponed hooks will be applied at the end, when the hookable objects are
instantiated, not before.

=head1 METHODS

=head2 psgi_app

Returns a code reference of a proper PSGI reply to a dispatched request.

It dispatches the request using the dispatcher (and provides the environment
variables) and then calls C<to_psgi> and returns that reply wrapped in a code
reference.

Please review L<PSGI> for more details on the protocol and how it works.

=head2 register_application

Adds another application to the C<apps> attribute (see above).

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
