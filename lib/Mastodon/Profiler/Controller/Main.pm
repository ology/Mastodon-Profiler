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
  my $ua = Mojo::UserAgent->new;
  my $tx = $ua->get($uri);
  my $response = _handle_response($tx);
  $uri = Mojo::URL->new("https://$server")
    ->path("/api/v1/accounts/$response->{id}/statuses")
    ->query(limit => 1);
  $tx = $ua->get($uri);
  my $posts = _handle_response($tx);
  # $uri = Mojo::URL->new("https://$server")
    # ->path("/api/v1/accounts/$response->{id}/followers");
  # $tx = $ua->get($uri);
  # my $followers = _handle_response($tx);
  # $uri = Mojo::URL->new("https://$server")
    # ->path("/api/v1/accounts/$response->{id}/following");
  # $tx = $ua->get($uri);
  # my $following = _handle_response($tx);
  $self->render(
    template  => 'main/index',
    profile   => $profile,
    response  => $response,
    posts     => $posts,
    # followers => $followers,
    # following => $following,
  );
}

sub _handle_response {
    my ($tx) = @_;
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
