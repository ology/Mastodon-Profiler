package Mastodon::Profiler::Controller::Main;
use Mojo::Base 'Mojolicious::Controller', -signatures;

use URI ();

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
  my $uri = URI->new("//$server");
  $uri->scheme('https');
  $uri->path('api/v1/accounts/lookup');
  $uri->query_form(acct => $user);
  $self->render(
    template => 'main/index',
    server   => $server,
    user     => $user,
    uri      => $uri->as_string,
  );
}

1;
