# ABSTRACT: Role for engines

package Dancer2::Core::Role::Engine;
{
  $Dancer2::Core::Role::Engine::VERSION = '0.11';
}
use Moo::Role;
use Dancer2::Core::Types;


with 'Dancer2::Core::Role::Hookable';


has environment => ( is => 'ro' );

has location => ( is => 'ro' );


has context => (
    is        => 'rw',
    isa       => InstanceOf ['Dancer2::Core::Context'],
    clearer   => 'clear_context',
    predicate => 1,
);


has config => (
    is      => 'rw',
    isa     => HashRef,
    default => sub { {} },
);

1;

__END__

=pod

=head1 NAME

Dancer2::Core::Role::Engine - Role for engines

=head1 VERSION

version 0.11

=head1 DESCRIPTION

This role is intended to be consumed by all engine roles. It contains all the
shared logic for engines.

This role consumes the L<Dancer2::Core::Role::Hookable> role.

=head1 ATTRIBUTES

=head2 environment

The value of the current environment

=head2 context

A L<Dancer2::Core::Context> object

=head2 config

An HashRef that hosts the configuration bits for the engine.

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
