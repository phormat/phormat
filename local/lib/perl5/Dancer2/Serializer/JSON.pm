# ABSTRACT: Serializer for handling JSON data

package Dancer2::Serializer::JSON;
{
  $Dancer2::Serializer::JSON::VERSION = '0.11';
}
use Moo;
use JSON ();

with 'Dancer2::Core::Role::Serializer';

has '+content_type' => (default => 'application/json');

# helpers
sub from_json {
    my $s = Dancer2::Serializer::JSON->new;
    $s->deserialize(@_);
}

sub to_json {
    my $s = Dancer2::Serializer::JSON->new;
    $s->serialize(@_);
}

# class definition
sub loaded {1}

sub serialize {
    my ( $self, $entity, $options ) = @_;

    # Why doesn't $self->config have this?
    my $config = $self->config;

    if ( $config->{allow_blessed} && !defined $options->{allow_blessed} ) {
        $options->{allow_blessed} = $config->{allow_blessed};
    }
    if ( $config->{convert_blessed} ) {
        $options->{convert_blessed} = $config->{convert_blessed};
    }
    $options->{utf8} = 1 if !defined $options->{utf8};

    JSON::to_json( $entity, $options );
}

sub deserialize {
    my ( $self, $entity, $options ) = @_;

    $options->{utf8} = 1 if !defined $options->{utf8};
    JSON::from_json( $entity, $options );
}

1;

__END__

=pod

=head1 NAME

Dancer2::Serializer::JSON - Serializer for handling JSON data

=head1 VERSION

version 0.11

=head1 DESCRIPTION

This is a serializer engine that allows you to turn Perl data structures into
JSON output and vice-versa.

=head1 ATTRIBUTES

=head2 content_type

Returns 'application/json'

=head1 METHODS

=head2 serialize($content)

Serializes a Perl data structure into a JSON string.

=head2 deserialize($content)

Deserializes a JSON string into a Perl data structure.

=head1 FUNCTIONS

=head2 from_json($content, \%options)

This is an helper available to transform a JSON data structure to a Perl data structures.

=head2 to_json($content, \%options)

This is an helper available to transform a Perl data structure to JSON.

Calling this function will B<not> trigger the serialization's hooks.

=head1 METHODS

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
