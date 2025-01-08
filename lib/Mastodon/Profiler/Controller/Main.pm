package Mastodon::Profiler::Controller::Main;
use Mojo::Base 'Mojolicious::Controller', -signatures;

use Lingua::EN::Opinion ();
use Mojo::DOM ();
use Mojo::JSON qw(decode_json);
use Mojo::URL ();
use Mojo::UserAgent ();
use Try::Tiny;

sub index ($self) {
  $self->render(
    profile  => undef,
    response => undef,
    posts    => undef,
    score    => undef,
  );
}

sub profiler ($self) {
  my $profile = $self->param('profile') || '';
  my (undef, $user, $server) = split '@', $profile;
  return $self->redirect_to('index') unless $user && $server;
  my $uri = Mojo::URL->new("https://$server")
    ->path('api/v1/accounts/lookup')
    ->query(acct => $user);
  my $response = _handle_request($uri);
  return $self->redirect_to('index') unless $response;
  $uri = Mojo::URL->new("https://$server")
    ->path("/api/v1/accounts/$response->{id}/statuses");
  my $last = _handle_request($uri);
  my $posts = [ reverse @$last ];
  my @statuses;
  my $content = '';
  for my $post (@$posts) {
    next unless $post->{content};
    push @statuses, $post;
    my $dom = Mojo::DOM->new($post->{content});
    my $text = $dom->all_text;
    $content .= "\n\n$text" if $text;
  }
  my $opinion = Lingua::EN::Opinion->new(text => $content, stem => 1);
  $opinion->analyze();
  my $score = $opinion->averaged_scores(4)->[0];
  my (%following, %followers);
#  my $count = 0;
#  while ($count < $response->{followers_count}) {
#    $uri = Mojo::URL->new("https://$server")
#      ->path("/api/v1/accounts/$response->{id}/followers")
#      ->query(min_id => 0, limit => 1);
#    my $followers = _handle_response($uri);
#  }
#  $count = 0;
#  while ($count < $response->{following_count}) {
#    $uri = Mojo::URL->new("https://$server")
#      ->path("/api/v1/accounts/$response->{id}/following")
#      ->query(min_id => 0, limit => 1);
#    my $following = _handle_response($uri);
#  }
#  my $mutual_count = 0;
  $self->render(
    template => 'main/index',
    profile  => $profile,
    response => $response,
    posts    => \@statuses,
    score    => $score,
  );
}

sub _handle_request {
    my ($uri) = @_;
    my $data;
    my $ua = Mojo::UserAgent->new;
    my $tx = $ua->get($uri);
    my $res;
    try {
      $res = $tx->result;
    }
    catch {
      warn "Can't get $uri: $!\n";
    };
    if ($res && $res->is_success) {
      my $body = $res->body;
      try {
        $data = decode_json($body);
      }
      catch {
        warn $body, "\n";
      };
    }
    else {
      warn "No data!\n";
    }
    return $data;
}

1;
