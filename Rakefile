require 'faraday'
require 'json'
require 'yaml'

class Spec
  include Enumerable

  def initialize(file)
    @file = file
  end

  def each
    @spec ||= YAML.load_file(@file)

    @spec.each do |name, spec|
      case spec
      when Enumerable
        yield name, spec
      when String
        yield name, [spec]
      when false, nil
        nil
      else
        raise "Unexpected value for test: #{name}"
      end
    end
  end

  def to_a
    flat_map { |name, tests| tests }
  end
end

class SM
  @@instances = {}

  def initialize(endpoint)
    @@client ||= Faraday.new(:url => 'http://sassmeister.com/app')
    @endpoint = endpoint
  end

  def self.[](endpoint)
    @@instances[endpoint] ||= self.new(endpoint)
  end

  def compile(file)
    response = @@client.post "#{@endpoint}/compile", {
      :syntax => 'SCSS',
      :input => File.read(file),
    }

    return nil if response.headers['content-type'] !~ /\/json$/

    JSON.parse(response.body)['css']
  end
end

class String
  def endpoint
    match(/\.(.+)\.css$/).captures.first
  end

  def spec
    "spec/spec/#{self}"
  end

  def support
    "#{self}/support.yml"
  end

  def indent(n)
    gsub(/^/, ' ' * n)
  end
end

class Rake::FileTask
  def endpoint
    name.endpoint
  end
end

class Hash
  def to_partial_yaml
    to_yaml.lines.drop(1).join
  end
end

ENGINES = {
  :ruby_sass_3_2 => '3.2',
  :ruby_sass_3_3 => '3.3',
  :ruby_sass_3_4 => '3.4',
  :libsass => 'lib',
}

SPEC = Spec.new('tests.yml')
SUPPORT = '_data/support.yml'
SUPPORTS = SPEC.to_a.map { |t| t.spec.support }

task :default => [:test]

task :test => ['spec', SUPPORT]

file SUPPORT => SUPPORTS do |t|
  File.open(t.name, 'w') do |file|
    SPEC.each do |name, tests|
      feature = {}

      tests.each do |test|
        YAML::load_file(test.spec.support).each do |engine, support|
          feature[engine] ||= { 'support' => true, 'tests' => {} }
          feature[engine]['support'] &&= support
          feature[engine]['tests'][test] = support
        end
      end

      file.write({ name => feature }.to_partial_yaml)
      file.write("\n")
    end
  end
end

EXPECTED = proc { |t| "#{File.dirname(t)}/expected_output.css" }

OUTPUTS = ENGINES.map do |engine, endpoint|
  proc { |t| "#{File.dirname(t)}/output.#{endpoint}.css" }
end

rule %r{^spec/.+/support.yml$} => [EXPECTED, *OUTPUTS] do |t|
  expected = File.read(t.source)

  support = t.sources.drop(1).map do |source|
    name = ENGINES.key(source.endpoint).to_s
    [name, File.read(source) == expected]
  end

  File.write(t.name, Hash[support].to_partial_yaml)
end

['', '.disabled'].each do |suffix|
  input = proc { |t| "#{File.dirname(t)}/input#{suffix}.scss" }

  rule %r{^spec/.+/output\..+\.css$} => [input] do |t|
    puts "Compiling #{t.source} for #{t.endpoint}"
    File.write(t.name, SM[t.endpoint].compile(t.source))
  end
end

directory 'spec' do |t|
  `git clone --depth 1 https://github.com/sass/sass-spec.git #{t}`
end
