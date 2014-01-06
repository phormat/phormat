# ABSTRACT: Role to provide commonly used responses

package Dancer2::Core::Role::StandardResponses;
{
  $Dancer2::Core::Role::StandardResponses::VERSION = '0.11';
}
use Moo::Role;


sub response {
    my ( $self, $ctx, $code, $message ) = @_;
    $ctx->response->status($code);
    $ctx->response->header( 'Content-Type', 'text/plain' );
    return $message;
}


sub response_400 {
    my ( $self, $ctx ) = @_;
    $self->response( $ctx, 400, 'Bad Request' );
}


sub response_404 {
    my ( $self, $ctx ) = @_;
    $self->response( $ctx, 404, 'Not Found' );
}


sub response_403 {
    my ( $self, $ctx ) = @_;
    $self->response( $ctx, 403, 'Unauthorized' );
}

1;

__END__

=pod

=head1 NAME

Dancer2::Core::Role::StandardResponses - Role to provide commonly used responses

=head1 VERSION

version 0.11

=head1 METHODS

=head2 response

Generic method that produces a response in the context given with a code and a
message:

    $self->response( $ctx, 404, "not found" );

=head2 response_400

Produces a 400 response in the context given.

=head2 response_404

Produces a 404 response in the context given.

=head2 response_403

Produces a 403 response in the context given.

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
