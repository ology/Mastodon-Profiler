package Mastodon::Profiler::Controller::Main;
use Mojo::Base 'Mojolicious::Controller', -signatures;

use Mojo::JSON qw(decode_json);
use Mojo::URL ();
use Mojo::UserAgent ();
use Try::Tiny;

sub index ($self) {
  my $server = $self->param('server') || '';
  my $user   = $self->param('user') || '';
  $self->render(
    server => $server,
    user   => $user,
  );
}

sub profiler ($self) {
  my $server = $self->param('server') || '';
  my $user = $self->param('user') || '';
  my $uri = Mojo::URL->new("https://$server")
    ->path('api/v1/accounts/lookup')
    ->query(acct => $user);
  my $ua = Mojo::UserAgent->new;
  my $tx = $ua->get($uri);
  my $data = _handle_response($tx);
  $self->render(
    template => 'main/index',
    server   => $server,
    user     => $user,
    uri      => $uri,
  );
}

sub _handle_response {
    my ($tx) = @_;
    my $data;
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
