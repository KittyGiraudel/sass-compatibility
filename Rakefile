require 'faraday'
require 'json'
require 'yaml'

# Classes {{{
# ===========

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

    type = response.headers['content-type']

    if type !~ /\/json(;|$)/
      raise Error.new "Unexpected #{type} response from SassMeister", response
    end

    data = JSON.parse(response.body)

    if not data.has_key?('css')
      raise Error.new "SassMeister returned an error: #{data['message']}", response
    end

    data['css']
  end

  #
  # SassMeister API error, with full response for debug.
  #
  class Error < StandardError
    attr_reader :response

    def initialize(msg, response)
      super(msg)
      @response = response
    end
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
  # Get all the output tasks from the main task prerequisites, and only
  # keep needed ones to get the final count.
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

  def spec?
    start_with?('spec/')
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
  :ruby_sass_3_2 => '3_2',
  :ruby_sass_3_3 => '3_3',
  :ruby_sass_3_4 => '3_4',
  :libsass => 'lib',
}

#
# Mapping with SassMeister endpoints.
#
SM_ENGINES = {
  '3_2' => '3.2',
  '3_3' => '3.3',
  '3_4' => '3.4',
  'lib' => 'lib',
}

#
# Specification file.
#
SPEC = YAML.load_file('_data/tests.yml')

#
# Flat array of tests, unaware of the feature names.
#
TESTS = SPEC.flat_map { |name, tests| tests }

#
# Stats file (containing engine stats).
#
STATS = '_data/stats.yml'

#
# SCSS version of the engine stats.
#
STATS_SCSS = '_sass/utils/_stats.scss'

#
# Support file (containing support results).
#
SUPPORT = '_data/support.yml'

task :default => [STATS_SCSS]

#
# Delete intermediate files.
#
task :clean do
  TESTS.each do |t|
    ['expected_output_clean.css', 'output.*.css', 'support.yml'].each do |g|
      Dir.glob("#{t}/#{g}").each { |f| File.delete f }
    end
  end
end

#
# SCSS version of the stats file.
#
file STATS_SCSS => [STATS] do |t|
  File.open(t.name, 'w') do |file|
    file.puts '$stats: ('

    YAML::load_file(STATS).each do |engine, result|
      file.puts "  '#{engine}': #{result['percentage'].round},"
    end

    file.puts ');'
  end
end

#
# Compute the engine stats.
#
file STATS => [SUPPORT] do |t|
  stats = {}
  keys = { true => 'passed', false => 'failed' }

  #
  # Aggregate results for each engine.
  #
  YAML::load_file(SUPPORT).each do |feature, engines|
    engines.each do |engine, result|
      stats[engine] ||= { 'passed' => 0, 'failed' => 0 }

      result['tests'].each do |test, passed|
        stats[engine][keys[passed]] += 1
      end
    end
  end

  stats.each do |engine, result|
    result['percentage'] = (result['passed'].to_f / TESTS.count * 100).round 2
  end

  File.write t.name, stats.to_partial_yaml
end

#
# From each individual test support file, build the aggregated YAML
# file.
#
task SUPPORT => TESTS.map { |t| "#{t}/support.yml" } do |t|
  File.open(t.name, 'w') do |file|
    SPEC.each do |name, tests|
      feature = {}

      #
      # Aggregate tests.
      #
      tests.each do |test|
        YAML::load_file("#{test}/support.yml").each do |engine, support|
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
end

TESTS.each do |test|

  #
  # Ensure sass-spec prerequisite if the test needs it.
  #
  Rake::Task[SUPPORT].prerequisites.unshift 'spec' if test.spec?

  #
  # Expected output (normalized).
  #
  expected = "#{test}/expected_output_clean.css"

  #
  # Outputs for each engine.
  #
  outputs = ENGINES.map { |engine, endpoint| "#{test}/output.#{endpoint}.css" }

  #
  # Build test support file from expected file and outputs.
  #
  file "#{test}/support.yml" => [expected, *outputs] do |t|
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
  SM_ENGINES.each do |engine, endpoint|
    file "#{test}/output.#{engine}.css" do |t|

      #
      # Find the input file.
      #
      input = ['', '.disabled']
        .map { |s| "#{test}/input#{s}.scss" }
        .find { |f| File.exist? f }


      puts "#{Progress.inc_s} Compiling #{input} for #{engine}"

      begin
        File.write t.name, SM[endpoint].compile(input).clean
      rescue SM::Error => e
        STDERR.puts "  #{e} with #{input} for #{engine}"

        File.write t.name, e.response.body
      end
    end
  end

  #
  # Clean version of the expectation file.
  #
  file "#{test}/expected_output_clean.css" => ["#{test}/expected_output.css"] do |t|
    File.write t.name, File.read(t.prerequisites.first).clean
  end
end

#
# Link `spec` directory.
#
directory 'spec' => 'sass-spec' do
  `ln -s sass-spec/spec .`
end

#
# Clone sass-spec repository.
#
directory 'sass-spec' do
  `git clone --depth 1 https://github.com/sass/sass-spec.git`
end
