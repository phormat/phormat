# ABSTRACT: Response object for Dancer2

package Dancer2::Core::Response;
{
  $Dancer2::Core::Response::VERSION = '0.11';
}

use Moo;

use Encode;
use Dancer2::Core::Types;

use Dancer2 ();
use Dancer2::Core::HTTP;

use overload
  '@{}' => sub { $_[0]->to_psgi },
  '""'  => sub { $_[0] };

with 'Dancer2::Core::Role::Headers';

sub BUILD {
    my ($self) = @_;
    $self->header( 'Server' => "Perl Dancer2 $Dancer2::VERSION" );
}

# boolean to tell if the route passes or not
has has_passed => (
    is      => 'rw',
    isa     => Bool,
    default => sub {0},
);


sub pass { shift->has_passed(1) }



has serializer => (
    is        => 'ro',
    isa       => Maybe( ConsumerOf ['Dancer2::Core::Role::Serializer'] ),
    predicate => 1,
);



has is_encoded => (
    is      => 'rw',
    isa     => Bool,
    default => sub {0},
);



has is_halted => (
    is      => 'rw',
    isa     => Bool,
    default => sub {0},
);


sub halt { shift->is_halted(1) }



has status => (
    is      => 'rw',
    isa     => Num,
    default => sub {200},
    lazy    => 1,
    coerce  => sub { Dancer2::Core::HTTP->status(shift) },

    # This trigger makes sure we drop the content whenever
    # we set the status to [23]04.
    trigger => sub {
        my ( $self, $value ) = @_;
        $self->content('') if $value =~ /^(?:1\d{2}|[23]04)$/;
        $value;
    },
);



has content => (
    is      => 'rw',
    isa     => Str,
    default => sub {''},
    coerce  => sub {
        my $value = shift;
        return "$value";
    },

   # This trigger makes sure we have a good content-length whenever the content
   # changes
    trigger => sub {
        my ( $self, $value ) = @_;
        $self->has_passed or $self->header( 'Content-Length' => length($value) );
        return $value;
    },
);

before content => sub {
    my $self = shift;
    if (ref($_[0]) and $self->has_serializer) {
        $_[0] = $self->serialize($_[0]);
    }
};


sub encode_content {
    my ($self) = @_;
    return if $self->is_encoded;
    return if $self->content_type !~ /^text/;

    # we don't want to encode an empty string, it will break the output
    $self->content or return;

    my $ct = $self->content_type;
    $self->content_type("$ct; charset=UTF-8")
      if $ct !~ /charset/;

    $self->is_encoded(1);
    my $content = $self->content( Encode::encode( 'UTF-8', $self->content ) );

    return $content;
}



sub to_psgi {
    my ($self) = @_;
    return [ $self->status, $self->headers_to_array, [ $self->content ], ];
}



# sugar for accessing the content_type header, with mimetype care
sub content_type {
    my $self = shift;

    if ( scalar @_ > 0 ) {
        my $runner   = Dancer2->runner;
        my $mimetype = $runner->mime_type->name_or_type(shift);
        $self->header( 'Content-Type' => $mimetype );
    }
    else {
        return $self->header('Content-Type');
    }
}

has _forward => (
    is  => 'rw',
    isa => HashRef,
);

sub forward {
    my ( $self, $uri, $params, $opts ) = @_;
    $self->_forward( { to_url => $uri, params => $params, options => $opts } );
}

sub is_forwarded {
    my $self = shift;
    $self->_forward;
}



sub redirect {
    my ( $self, $destination, $status ) = @_;
    $self->status( $status || 302 );

    # we want to stringify the $destination object (URI object)
    $self->header( 'Location' => "$destination" );
}



sub error {
    my $self = shift;

    my $error = Dancer2::Core::Error->new(
        response => $self,
        @_,
    );

    $error->throw;
    return $error;
}



sub serialize {
    my ($self, $content) = @_;
    return unless $self->has_serializer;

    $content = $self->serializer->serialize($content)
        or return;

    $self->content_type($self->serializer->content_type);
    return $content;
}

1;

__END__

=pod

=head1 NAME

Dancer2::Core::Response - Response object for Dancer2

=head1 VERSION

version 0.11

=head1 ATTRIBUTES

=head2 is_encoded

Flag to tell if the content has already been encoded.

=head2 is_halted

Flag to tell whether or not the response should continue to be processed.

=head2 status

The HTTP status for the response.

=head2 content

The content for the response, stored as a string.  If a reference is passed, the
response will try coerce it to a string via double quote interpolation.

Whenever the content changes, it recalculates and updates the Content-Length header,
unless the response has_passed.

=head1 METHODS

=head2 pass

Set has_passed to true.

=head2 serializer()

Returns the optional serializer object used to deserialize request parameters

=head2 halt

Shortcut to halt the current response by setting the is_halted flag.

=head2 encode_content

Encodes the stored content according to the stored L<content_type>.  If the content_type
is a text format C<^text>, then no encoding will take place.

Interally, it uses the L<is_encoded> flag to make sure that content is not encoded twice.

If it encodes the content, then it will return the encoded content.  In all other
cases it returns C<false>.

=head2 to_psgi

Converts the response object to a PSGI array.

=head2 content_type($type)

A little sugar for setting or accessing the content_type of the response, via the headers.

=head2 redirect ($destination, $status)

Sets a header in this response to give a redirect to $destination, and sets the
status to $status.  If $status is omitted, or false, then it defaults to a status of
302.

=head2 error( @args )

    $response->error( message => "oops" );

Creates a L<Dancer2::Core::Error> object with the given I<@args> and I<throw()>
it against the response object. Returns the error object.

=head2 serialize( $content )

    $response->serialize( $content );

Serialize and return $content with the response's serializer.
set content-type accordingly.

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
