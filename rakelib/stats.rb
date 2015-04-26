require 'yaml'

#
# Stats file (containing engine stats).
#
STATS = '_data/stats.yml'

#
# SCSS version of the engine stats.
#
STATS_SCSS = '_sass/utils/_stats.scss'

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
