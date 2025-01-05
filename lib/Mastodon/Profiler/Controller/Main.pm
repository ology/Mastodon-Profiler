package Mastodon::Profiler::Controller::Main;
use Mojo::Base 'Mojolicious::Controller', -signatures;

sub index ($self) {
  $self->render(msg => 'Welcome!');
}

1;
