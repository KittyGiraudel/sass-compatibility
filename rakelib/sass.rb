require 'json'
require 'socket'

DOCKER_ENGINES = {}

DOCKER_ENV = if RUBY_PLATFORM[/darwin/]
  # Get Boot2Docker environment variables.
  `boot2docker shellinit`.split(' ').values_at(1, 3, 5).join(' ')
else
  ''
end

def docker_name(engine, version)
  "sass-compatibility.#{engine}.#{version}"
end

def start_engine(engine, version)
  name = docker_name(engine, version)

  puts "Building #{engine} #{version} container"

  `#{DOCKER_ENV} docker build -t #{name} #{docker_path(engine, version)}`

  puts "Running #{engine} #{version} in background"

  fork do
    `#{DOCKER_ENV} docker run --name #{name} --rm #{name}`
  end

  # Exit is propagated in child processed, but this code needs
  # to execute only in the parent.
  pid = Process.pid

  at_exit do
    if Process.pid == pid then
      puts "Killing #{name}"
      `#{DOCKER_ENV} docker kill #{name}`
    end
  end

  sleep 1

  info = JSON.parse `docker inspect #{name}`
  ip = info[0]['NetworkSettings']['IPAddress']

  DOCKER_ENGINES[engine] ||= {}
  DOCKER_ENGINES[engine][version] = ip

  puts "Container has IP #{ip}"
end

def sass(engine, version, input)
  s = TCPSocket.new DOCKER_ENGINES[engine][version], 1337
  s.write File.read(input)
  s.close_write
  s.read
end

puts
puts 'DOCKER INIT'
puts

ENGINES.each do |engine, versions|
  versions.each do |version|
    start_engine(engine, version)
  end
end

puts

at_exit do
  puts
  puts 'DOCKER EXIT'
  puts
end
