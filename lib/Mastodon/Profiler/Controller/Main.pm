package Mastodon::Profiler::Controller::Main;
use Mojo::Base 'Mojolicious::Controller', -signatures;

use Lingua::EN::Opinion ();
use Mojo::JSON qw(decode_json);
use Mojo::URL ();
use Mojo::UserAgent ();
use Try::Tiny;

sub index ($self) {
  $self->render(
    profile  => undef,
    response => undef,
    posts    => undef,
    opinions => undef,
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
  my @opinions;
  my $opinion = Lingua::EN::Opinion->new(text => $posts->[0]->{content}, stem => 1);
  $opinion->analyze();
  push @opinions, $opinion->averaged_scores(5);
  $opinion = Lingua::EN::Opinion->new(text => $posts->[-1]->{content}, stem => 1);
  $opinion->analyze();
  push @opinions, $opinion->averaged_scores(5);
  $self->render(
    template => 'main/index',
    profile  => $profile,
    response => $response,
    posts    => $posts,
    opinions => \@opinions,
  );
}

sub _handle_request {
    my ($uri) = @_;
    my $data = {};
    my $ua = Mojo::UserAgent->new;
    my $tx = $ua->get($uri);
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
