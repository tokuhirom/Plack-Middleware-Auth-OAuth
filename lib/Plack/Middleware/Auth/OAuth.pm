package Plack::Middleware::Auth::OAuth;
use strict;
use warnings;
our $VERSION = '0.01';

use parent qw(Plack::Middleware);

use Plack::Request;
use Plack::Util::Accessor qw(consumer_key consumer_secret);

use OAuth::Lite::Util qw(parse_auth_header);
use OAuth::Lite::ServerUtil;

sub prepare_app {
    my $self = shift;

    die 'requires consumer_key'    unless $self->consumer_key;
    die 'requires consumer_secret' unless $self->consumer_secret;
}

sub call {
    my ($self, $env) = @_;

    return $self->validate($env) ? $self->app->($env) : $self->unauthorized;
}

sub validate {
    my ($self, $env) = @_;

    my $auth = $env->{HTTP_AUTHORIZATION} or return 0;

    my ($realm, $params) = parse_auth_header($auth);
    my $util = OAuth::Lite::ServerUtil->new(strict => 0);
    $util->support_signature_method('HMAC-SHA1');

    return 0 unless $util->validate_params($params);
    return 0 unless $params->{oauth_consumer_key} eq $self->consumer_key;

    my $req = Plack::Request->new($env);

    return $util->verify_signature(
        method          => $req->method,
        url             => $req->uri,
        params          => $params,
        consumer_secret => $self->consumer_secret,
        token_secret    => $params->{oauth_token_secret},
    );
}

sub unauthorized {
    my $self = shift;

    my $body = 'Authorization required';
    return [
        401,
        [
            'Content-Type'    => 'text/plain',
            'Content-Lentgth' => length $body,
        ],
        [$body],
    ];
}
1;
__END__

=head1 NAME

Plack::Middleware::Auth::OAuth -

=head1 SYNOPSIS

  use Plack::Middleware::Auth::OAuth;

=head1 DESCRIPTION

Plack::Middleware::Auth::OAuth is

=head1 AUTHOR

Hideo Kimura E<lt>hide@cpan.orgE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut