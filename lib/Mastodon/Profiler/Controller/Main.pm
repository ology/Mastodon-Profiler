package Mastodon::Profiler::Controller::Main;
use Mojo::Base 'Mojolicious::Controller', -signatures;

sub index ($self) {
  my $url = $self->param('url') || '';
  $self->render(
    url => $url,
  );
}

sub profiler ($self) {
  my $url = $self->param('url') || '';
  $self->redirect_to($self->url_for('index')->query(url => $url));
}

1;
