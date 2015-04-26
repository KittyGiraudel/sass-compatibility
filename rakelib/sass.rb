DOCKER_ENGINES = {
  'ruby-sass' => {
    '3.2' => 'xzyfer/docker-ruby-sass:3.2',
    '3.3' => 'xzyfer/docker-ruby-sass:3.3',
    '3.4' => 'xzyfer/docker-ruby-sass:3.4',
  },
  'libsass' => {
    '3.1' => 'xzyfer/docker-libsass:3.1.0',
    '3.2' => 'xzyfer/docker-libsass:3.2.0-beta.6',
  },
}

DOCKER_PREFIX = if RUBY_PLATFORM[/darwin/]
  # Get Boot2Docker environment variables.
  `boot2docker shellinit`.split(' ').values_at(1, 3, 5).join(' ')
else
  ''
end

def sass(engine, version, input)
  release = DOCKER_ENGINES[engine][version]
  options = "--interactive --tty --rm --volume #{ENV['PWD']}:#{ENV['PWD']} --workdir #{ENV['PWD']}"

  `#{DOCKER_PREFIX} docker run #{options} #{release} #{input}`
end
