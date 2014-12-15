Sass Compatibility
==================

Sass compatibility issues between different engines.

## Building

Be sure to have Ruby and Bundler installed.

```sh
bundle install
bundle exec rake
```

The Rakefile will:

* Clone [sass-spec](https://github.com/sass/sass-spec) and symlink
  `sass-spec/spec` to `spec` if needed.
* Load tests from `_data/tests.yml`.
* Compile each test input with all supported engines, and normalize the
  output CSS (creating `output.#{engine}.css` files in the test
  directory).
* Create a `expected_output_clean.css` from `expected_output.css` for
  each test using the same normalization rules.
* Compare the output of each engine with the expected output and create
  a `support.yml` file in each test directory (containing the results
  for this test).
* Aggregate the test data for every feature described in
  `_data/tests.yml`, in `_data/support.yml`.

## I/O YAML structure

### `_data/tests.yml`

This file contains a list of features to test, with one or multiple
tests (relative to the project root) for each feature.

```yaml
call_function: spec/basic/60_call

angle_conversion:
  - spec/libsass-clised-issues/issue_666/angle
  - spec/libsass-clised-issues/issue_666/length
```

Features with falsy values are ignored.

A test, according to sass-spec, is a directory with `input.scss` and
`expected_output.css` files.

### `_data/support.yml`

All the features described in `_data/tests.yml` are present, but will
now contain the test results, for each engine, with details for each
individual test.

If `support` is `true` for an engine, all the tests passed. If `false`,
all the tests failed. If `nil`, the results were mixed.

```yaml
call_function:
  ruby_sass_3_2:
    support: false
    tests:
      spec/basic/60_call: false
  ruby_sass_3_4:
    support: true
    tests:
      spec/basic/60_call: true

angle_conversion:
  ruby_sass_3_2:
    support:
    tests:
      spec/libsass-closed-issues/issue_666/angle: false
      spec/libsass-closed-issues/issue_666/length: true
  ruby_sass_3_4:
    support: true
    tests:
      spec/libsass-closed-issues/issue_666/angle: true
      spec/libsass-closed-issues/issue_666/length: true
```

**Note:** I stripped some engines from the example output to keep it
lightweight.

## Credits

* [Chris Eppstein](https://twitter.com/chriseppstein) and [Natalie Weizenbaum](https://twitter.com/nex3) for Ruby Sass;
* [Aaron Leung](https://twitter.com/akhleung) and [Hampton Catlin](https://twitter.com/hcatlin) for LibSass;
* [SassMeister](https://twitter.com/sassmeisterapp) for lending their backend to run tests;
* [Valérian Galliat](https://twitter.com/valeriangalliat) for the test runner;
* [Michael Mifsud](https://twitter.com/xzyfer) for his help;
* [Team Sass Design](https://twitter.com/teamsassdesign) for their great style guide;
* [SubtlePatterns](http://subtlepatterns.com/) for the pattern in use on the site.
