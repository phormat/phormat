package Dancer2::Core::Context;
{
  $Dancer2::Core::Context::VERSION = '0.11';
}

# ABSTRACT: handles everything proper to a request's context.

use Moo;
use URI::Escape;
use Carp 'croak';

use Dancer2::Core::Types;
use Dancer2::Core::Request;
use Dancer2::Core::Response;
use Dancer2::Core::Cookie;



has app => (
    is        => 'rw',
    isa       => InstanceOf ['Dancer2::Core::App'],
    weak_ref  => 1,
    predicate => 1,
);


# the PSGI-env to use for building the request to process
# this is the only mandatory argument to a context
has env => (
    is       => 'ro',
    required => 1,
    isa      => HashRef,
);


# the incoming request
has request => (
    is      => 'rw',
    lazy    => 1,
    builder => '_build_request',
    isa     => InstanceOf ['Dancer2::Core::Request'],
);

sub _build_request {
    my ($self) = @_;

    # If we have an app, get the serialization engine
    my $engine = $self->app->engine('serializer')
        if $self->has_app;

    my $req = Dancer2::Core::Request->new( env => $self->env,
        $engine ? ( serializer => $engine ) : (),
    );

    # Log deserialization errors
    $self->app->log( core => "Failed to deserialize the request : "
        . $engine->error ) if ( $engine && $engine->has_error );

    return $req;
}

# a buffer for per-request variables
has buffer => (
    is      => 'rw',
    isa     => HashRef,
    default => sub { {} },
);


sub vars { shift->buffer }


sub var {
    my $self = shift;
    @_ == 2
      ? $self->buffer->{ $_[0] } = $_[1]
      : $self->buffer->{ $_[0] };
}


# a set of changes to apply to the response
# that HashRef will should be passed as attributes to a response object
has response => (
    is      => 'rw',
    isa     => InstanceOf ['Dancer2::Core::Response'],
    lazy    => 1,
    default => sub {
        my $self = shift;

        my $engine = $self->has_app
            ? $self->app->engine('serializer')
            : undef;

        return Dancer2::Core::Response->new(
            $engine ? (serializer => $engine) : ()
        );
    },
);


sub cookies { shift->request->cookies(@_) }


sub cookie {
    my $self = shift;

    return $self->request->cookies->{ $_[0] } if @_ == 1;

    # writer
    my ( $name, $value, %options ) = @_;
    my $c =
      Dancer2::Core::Cookie->new( name => $name, value => $value, %options );
    $self->response->push_header( 'Set-Cookie' => $c->to_header );
}


sub redirect {
    my ( $self, $destination, $status ) = @_;

    # RFC 2616 requires an absolute URI with a scheme,
    # turn the URI into that if it needs it

    # Scheme grammar as defined in RFC 2396
    #  scheme = alpha *( alpha | digit | "+" | "-" | "." )
    my $scheme_re = qr{ [a-z][a-z0-9\+\-\.]* }ix;
    if ( $destination !~ m{^ $scheme_re : }x ) {
        $destination = $self->request->uri_for( $destination, {}, 1 );
    }

    $self->response->redirect( $destination, $status );
    # Short circuit any remaining before hook / route code
    # ('pass' and after hooks are still processed)
    $self->with_return->($self->response) if $self->has_with_return;
}


sub halt {
   my ($self) = @_;
   $self->response->halt;
   # Short citcuit any remaining hook/route code
   $self->with_return->($self->response) if $self->has_with_return;
}


has session => (
    is        => 'rw',
    isa       => Session,
    lazy      => 1,
    builder   => '_build_session',
    predicate => '_has_session',
    clearer   => 1,
);

sub _build_session {
    my ($self) = @_;
    my $session;

    # Find the session engine
    my $engine = $self->app->engine('session');

    # find the session cookie if any
    if ( !$self->destroyed_session ) {
        my $session_id;
        my $session_cookie = $self->cookie( $engine->cookie_name );
        if ( defined $session_cookie ) {
            $session_id = $session_cookie->value;
        }

        # if we have a session cookie, try to retrieve the session
        if ( defined $session_id ) {
            eval { $session = $engine->retrieve( id => $session_id ) };
            croak "Fail to retrieve session: $@"
              if $@ && $@ !~ /Unable to retrieve session/;
        }
    }

    # create the session if none retrieved
    return $session ||= $engine->create();
}


sub has_session {
    my ($self) = @_;

    my $engine = $self->app->engine('session');

    return $self->_has_session
      || ( $self->cookie( $engine->cookie_name )
        && !$self->has_destroyed_session );
}


has destroyed_session => (
    is        => 'rw',
    isa       => InstanceOf ['Dancer2::Core::Session'],
    predicate => 1,
);


sub destroy_session {
    my ($self) = @_;

    # Find the session engine
    my $engine = $self->app->engine('session');

    # Expire session, set the expired cookie and destroy the session
    # Setting the cookie ensures client gets an expired cookie unless
    # a new session is created and supercedes it
    my $session = $self->session;
    $session->expires(-86400);    # yesterday
    $engine->destroy( id => $session->id );

    # Clear session in context and invalidate session cookie in request
    $self->destroyed_session($session);
    $self->clear_session;

    return;
}



has with_return => (
    is        => 'rw',
    predicate => 1,
    clearer   => 'clear_with_response',
);

1;

__END__

=pod

=head1 NAME

Dancer2::Core::Context - handles everything proper to a request's context.

=head1 VERSION

version 0.11

=head1 ATTRIBUTES

=head2 app

Reference to the L<Dancer2::Core::App> object for the current application.

=head2 env

Read-only accessor to a PSGI environment hash.

=head2 request

A L<Dancer2::Core::Request> object, built from the PSGI environment variable for this request.

=head2 response

A L<Dancer2::Core::Response> object, used to set content, headers and HTTP status codes.

=head2 session

Handle for the current session object, if any

=head2 destroyed_session

We cache a destroyed session here; once this is set we must not attempt to
retrieve the session from the cookie in the request.  If no new session is
created, this is set (with expiration) as a cookie to force the browser to
expire the cookie.

=head2 with_return

Used to cache the coderef from L<Return::MultiLevel> within the dispatcher.

=head1 METHODS

=head2 vars

Returns a hashref of all per-request variables stored in this object.

=head2 var

By-name interface to variables stored in this context object.

  my $stored = $context->var('some_variable');

returns the value of 'some_variable', while

  $context->var('some_variable' => 'value');

will set it.

=head2 cookies

Shortcut that dispatches to L<Dancer2::Core::Request>'s cookies method.

=head2 cookie

Get a cookie from the L<request> object, or set one in the L<response> object.

=head2 redirect($destination, $status)

Sets a redirect in the response object.  If $destination is not an absolute URI, then it will
be made into an absolute URI, relative to the URI in the request.

=head2 halt

Flag the response object as 'halted'.

If called during request dispatch, immediatly returns the response
to the dispatcher and after hooks will not be run.

=head2 has_session

Returns true if session engine has been defined and if either a session object
has been instantiated in the context or if a session cookie was found and not
subsequently invalidated.

=head2 destroy_session

Destroys the current session and ensures any subsequent session is created
from scratch and not from the request session cookie

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
