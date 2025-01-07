package Mastodon::Profiler::Controller::Main;
use Mojo::Base 'Mojolicious::Controller', -signatures;

use Mojo::JSON qw(decode_json);
use Mojo::URL ();
use Mojo::UserAgent ();
use Try::Tiny;

sub index ($self) {
  $self->render(
    profile   => undef,
    response  => undef,
    posts     => undef,
    followers => undef,
    following => undef,
  );
}

sub profiler ($self) {
  my $profile = $self->param('profile') || '';
  my (undef, $user, $server) = split '@', $profile;
  my $uri = Mojo::URL->new("https://$server")
    ->path('api/v1/accounts/lookup')
    ->query(acct => $user);
  my $response = _handle_request($uri);
  $uri = Mojo::URL->new("https://$server")
    ->path("/api/v1/accounts/$response->{id}/statuses")
    ->query(min_id => 0, limit => 1);
  my $first = _handle_request($uri);
  $uri = Mojo::URL->new("https://$server")
    ->path("/api/v1/accounts/$response->{id}/statuses")
    ->query(limit => 1);
  my $last = _handle_request($uri);
  my $posts = [ $first->[0], $last->[0] ];
  $self->render(
    template => 'main/index',
    profile  => $profile,
    response => $response,
    posts    => $posts,
  );
}

sub _handle_request {
    my ($uri) = @_;
    my $ua = Mojo::UserAgent->new;
    my $tx = $ua->get($uri);
    my $data = {};
    my $res = $tx->result;
    if ($res->is_success) {
      my $body = $res->body;
      try {
        $data = decode_json($body);
      }
      catch {
        warn $body, "\n";
      };
    }
    else {
      warn "Connection error: ", $res->message, "\n";
    }
    return $data;
}

1;
