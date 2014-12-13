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

#
# Global progress indicator.
#
class Progress

  #
  # Actual count of compiled files.
  #
  @@actual = 0

  #
  # The count of files to update.
  #
  def self.count
    @@cached_count ||= Rake::Task[SUPPORT].prerequisites
      .flat_map { |p| Rake::Task[p].prerequisites.drop 1 }
      .map { |p| Rake::Task[p] }
      .find_all(&:needed?)
      .count
  end

  #
  # Increment the compiled files count.
  #
  def self.inc
    @@actual += 1
  end

  def self.inc_s
    self.inc
    self.to_s
  end

  #
  # Text progress.
  #
  def self.to_s
    "(#{@@actual}/#{self.count})"
  end
end

# }}}

# Syntaxic sugar {{{
# ==================

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

MUTEX = Mutex.new

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
multitask SUPPORT => SUPPORTS do |t|
  file = File.open(t.name, 'w')

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

    file << { name => feature }.to_partial_yaml
    file << "\n"
  end
end

SPEC.to_a.each do |test|

  #
  # Expected output (normalized).
  #
  expected = "#{test.spec}/expected_output_clean.css"

  #
  # Outputs for each engine.
  #
  outputs = ENGINES.map { |engine, endpoint| "#{test.spec}/output.#{endpoint}.css" }

  #
  # Build test support file from expected file and outputs.
  #
  file test.spec.support => [expected, *outputs] do |t|
    expected_output = File.read expected

    support = outputs.map do |source|
      name = ENGINES.key(source.endpoint).to_s
      [name, File.read(source) == expected_output]
    end

    File.write t.name, Hash[support].to_partial_yaml
  end

  #
  # Compile output for different engines, from an input CSS file.
  #
  ENGINES.each do |engine, endpoint|
    file "#{test.spec}/output.#{endpoint}.css" do |t|

      #
      # Find the input file.
      #
      input = ['', '.disabled']
        .map { |s| "#{test.spec}/input#{s}.scss" }
        .find { |f| File.exist? f }


      MUTEX.synchronize {
        puts "#{Progress.inc_s} Compiling #{input} for #{endpoint}"
      }

      File.write t.name, SM[endpoint].compile(input).clean
    end
  end

  #
  # Clean version of the expectation file.
  #
  file "#{test.spec}/expected_output_clean.css" => ["#{test.spec}/expected_output.css"] do |t|
    File.write t.name, File.read(t.prerequisites.first).clean
  end
end

#
# Clone sass-spec repository.
#
directory 'spec' do |t|
  `git clone --depth 1 https://github.com/sass/sass-spec.git #{t}`
end
