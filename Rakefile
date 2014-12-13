require 'faraday'
require 'json'
require 'yaml'

# Classes {{{
# ===========

#
# Specification YAML file wrapper.
#
# Handle different types of input (signle test, array of tests, falsy
# tests) and yield uniform specification tests.
#
class Spec
  include Enumerable

  def initialize(file)
    @file = file
  end

  #
  # Yeald the feature name and an array of tests for each feature.
  #
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

  #
  # Get a flat array of tests, unaware of the feature name.
  #
  def to_a
    flat_map { |name, tests| tests }
  end
end

#
# SassMeister API wrapper.
#
# Access an endpoint singleton with `SM[endpoint]`, for example
# `SM['lib']` for libsass.
#
# Example:
#
#     SM['lib'].compile('path/to/example.scss')
#
class SM
  @@instances = {}

  def initialize(endpoint)
    @@client ||= Faraday.new(:url => 'http://sassmeister.com/app')
    @endpoint = endpoint
  end

  def self.[](endpoint)
    @@instances[endpoint] ||= self.new(endpoint)
  end

  #
  # Compile given file and get the output CSS.
  #
  def compile(file)
    response = @@client.post "#{@endpoint}/compile", {
      :syntax => 'SCSS',
      :input => File.read(file),
    }

    return '' if response.headers['content-type'] !~ /\/json(;|$)/

    JSON.parse(response.body)['css']
  end
end

# }}}

# Syntaxic sugar {{{
# ==================

# Endpoint access {{{
# -------------------

class String
  def endpoint
    match(/\.(.+)\.css$/).captures.first
  end
end

class Rake::FileTask
  def endpoint
    name.endpoint
  end
end

# }}}

class String

  def spec
    "spec/spec/#{self}"
  end

  def support
    "#{self}/support.yml"
  end

  def indent(n)
    gsub(/^/, ' ' * n)
  end

  #
  # Normalize CSS.
  #
  def clean
    lines.reject { |l| l[/^@charset/] }.join
      .gsub(/\s+/, ' ')
      .gsub(/ *\{/, " {\n")
      .gsub(/([;,]) */, "\\1\n")
      .gsub(/ *\} */, " }\n")
      .strip
  end
end

#
# Get YAML without header line.
#
class Hash
  def to_partial_yaml
    to_yaml.lines.drop(1).join
  end
end

# }}}

#
# Supported engines.
#
ENGINES = {
  :ruby_sass_3_2 => '3.2',
  :ruby_sass_3_3 => '3.3',
  :ruby_sass_3_4 => '3.4',
  :libsass => 'lib',
}

#
# Specification file.
#
SPEC = Spec.new('tests.yml')

#
# Destination file (containing support results).
#
SUPPORT = '_data/support.yml'

#
# Individual support file for each test.
#
SUPPORTS = SPEC.to_a.map { |t| t.spec.support }

task :default => [:test]

#
# Delete intermediate files.
#
task :clean do
  Dir.glob('spec/**/expected_output_clean.css').each { |f| File.delete(f) }
  Dir.glob('spec/**/output.*.css').each { |f| File.delete(f) }
  Dir.glob('spec/**/support.yml').each { |f| File.delete(f) }
end

#
# Clone sass-spec, then build support file.
#
task :test => ['spec', SUPPORT]

#
# From each individual test support file, build the aggregated YAML
# file.
#
file SUPPORT => SUPPORTS do |t|
  File.open(t.name, 'w') do |file|
    SPEC.each do |name, tests|
      feature = {}

      #
      # Aggregate tests.
      #
      tests.each do |test|
        YAML::load_file(test.spec.support).each do |engine, support|
          feature[engine] ||= { 'support' => [], 'tests' => {} }
          feature[engine]['support'] << support
          feature[engine]['tests'][test] = support
        end
      end

      #
      # Determine `true` (all good), `false` (all fail) or `nil` (mixed)
      # support status.
      #
      feature.each do |_, engine|
        engine['support'] = engine['support'].all? || (engine['support'].include?(true) ? nil : false)
      end

      file.write({ name => feature }.to_partial_yaml)
      file.write("\n")
    end
  end
end

#
# Expected output (normalized).
#
EXPECTED = proc { |t| "#{File.dirname(t)}/expected_output_clean.css" }

#
# Outputs for each engine.
#
OUTPUTS = ENGINES.map do |engine, endpoint|
  proc { |t| "#{File.dirname(t)}/output.#{endpoint}.css" }
end

#
# Build individual support file from outputs and expected file.
#
rule %r{^spec/.+/support.yml$} => [EXPECTED, *OUTPUTS] do |t|
  expected = File.read(t.source).clean

  support = t.sources.drop(1).map do |source|
    name = ENGINES.key(source.endpoint).to_s
    [name, File.read(source) == expected]
  end

  File.write(t.name, Hash[support].to_partial_yaml)
end

#
# Compile output for different engines, from an input CSS file.
#
['', '.disabled'].each do |suffix|
  input = proc { |t| "#{File.dirname(t)}/input#{suffix}.scss" }

  rule %r{^spec/.+/output\..+\.css$} => [input] do |t|
    puts "Compiling #{t.source} for #{t.endpoint}"
    File.write(t.name, SM[t.endpoint].compile(t.source).clean)
  end
end

#
# Clean version of the expectation file.
#
rule %r{^spec/.+/expected_output_clean.css$} => [
  proc { |t| t.sub(/_clean\.css$/, '.css') }
] do |t|
  File.write(t.name, File.read(t.source).clean)
end

#
# Clone sass-spec repository.
#
directory 'spec' do |t|
  `git clone --depth 1 https://github.com/sass/sass-spec.git #{t}`
end
