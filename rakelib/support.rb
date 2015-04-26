require 'yaml'

#
# Support file (containing support results).
#
SUPPORT = '_data/support.yml'

#
# Get output suffix from engine and version.
#
def output_suffix(engine, version, strip = true)
  engine = engine.gsub('-', '_')
  version = version.gsub('.', '_')

  if engine == 'ruby_sass' and strip
    version
  else
    "#{engine}_#{version}"
  end
end

#
# Get output file from test, engine and version.
#
def output(test, engine, version)
  "#{test}/output.#{output_suffix(engine, version)}.css"
end

namespace :support do
  task :clean do
    TESTS.each do |t|
      ['expected_output_clean.css', 'output.*.css', 'support.yml'].each do |g|
        Dir.glob("#{t}/#{g}").each { |f| File.delete f }
      end
    end
  end
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
  Rake::Task[SUPPORT].prerequisites.unshift 'spec' if test.start_with?('spec/')

  #
  # Expected output (normalized).
  #
  expected = "#{test}/expected_output_clean.css"

  #
  # Outputs for each engine.
  #
  outputs = ENGINES.flat_map do |engine, versions|
    versions.map { |version| output(test, engine, version) }
  end

  #
  # Build test support file from expected file and outputs.
  #
  file "#{test}/support.yml" => [expected, *outputs] do |t|
    expected_output = File.read expected

    support = ENGINES.flat_map do |engine, versions|
      versions.map do |version|
        name = output_suffix(engine, version, false)
        [name, File.read(output(test, engine, version)) == expected_output]
      end
    end

    File.write t.name, Hash[support].to_partial_yaml
  end

  #
  # Compile output for different engines, from an input CSS file.
  #
  ENGINES.each do |engine, versions|
    versions.each do |version|
      file output(test, engine, version) do |t|

        #
        # Find the input file.
        #
        input = ['', '.disabled']
          .map { |s| "#{test}/input#{s}.scss" }
          .find { |f| File.exist? f }

        puts "#{Progress.inc_s} Compiling #{input} for #{engine} #{version}"

        result = sass engine, version, input

        File.write t.name, result.normalize_css
      end
    end
  end

  #
  # Clean version of the expectation file.
  #
  file "#{test}/expected_output_clean.css" => ["#{test}/expected_output.css"] do |t|
    File.write t.name, File.read(t.prerequisites.first).normalize_css
  end
end
