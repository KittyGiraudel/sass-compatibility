require 'erb'

DOCKER_PREFIX = 'docker'
DOCKER_ALL = []

dockerfile_erb = "#{DOCKER_PREFIX}/Dockerfile.erb"
dockerfile = ERB.new File.read(dockerfile_erb)

def get_binding
  binding
end

def docker_path(engine, version)
  "#{DOCKER_PREFIX}/#{engine}-#{version}"
end

ENGINES.each do |engine, versions|
  command = "#{DOCKER_PREFIX}/#{engine}.command"

  versions.each do |version|
    dir = docker_path(engine, version)
    from = "#{dir}/from"

    DOCKER_ALL << "#{dir}/Dockerfile"

    file "#{dir}/Dockerfile" => [dockerfile_erb, from, command] do
      b = get_binding
      b.local_variable_set :from, File.read(from).strip
      b.local_variable_set :command, File.read(command).strip

      File.write "#{dir}/Dockerfile", dockerfile.result(b)
    end
  end
end

task :docker => DOCKER_ALL

namespace :docker do
  task :clean do
    DOCKER_ALL.select { |f| File.exist?(f) }.each { |f| File.delete(f) }
  end
end
