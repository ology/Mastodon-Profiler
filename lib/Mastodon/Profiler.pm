package Mastodon::Profiler;
use Mojo::Base 'Mojolicious', -signatures;

sub startup ($self) {
  my $config = $self->plugin('NotYAMLConfig');
  $self->secrets($config->{secrets});

  my $r = $self->routes;
  $r->get('/')->to('Main#index');
  $r->post('/')->to('Main#profiler');
}

1;
