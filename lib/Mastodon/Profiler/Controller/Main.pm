package Mastodon::Profiler::Controller::Main;
use Mojo::Base 'Mojolicious::Controller', -signatures;

use Mojo::JSON qw(decode_json);
use Mojo::URL ();
use Mojo::UserAgent ();
use Try::Tiny;

sub index ($self) {
  my $profile = $self->param('profile') || '';
  $self->render(
    profile  => $profile,
    response => undef,
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
  $self->render(
    template => 'main/index',
    profile  => $profile,
    response => $response,
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
