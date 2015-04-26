require 'yaml'

ENGINES = {
  'ruby-sass' => ['3.2', '3.3', '3.4'],
  'libsass' => ['3.1', '3.2'],
}

#
# Specification file.
#
SPEC = YAML.load_file('_data/tests.yml')

#
# Flat array of tests, unaware of the feature names.
#
TESTS = SPEC.flat_map { |name, tests| tests }

require './rakelib/helpers'
require './rakelib/progress'
require './rakelib/sass'
require './rakelib/spec'
require './rakelib/support'
require './rakelib/stats'

task :default => [STATS_SCSS]

#
# Delete intermediate files.
#
task :clean => ['support:clean']
