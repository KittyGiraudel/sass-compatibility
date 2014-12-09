#
# Executable to minify CSS.
#
UGLIFY = node_modules/uglifycss/uglifycss

#
# Find all tests (all directories one level under `tests`).
#
TESTS := $(shell find tests -mindepth 1 -maxdepth 1 -type d | sort)
TESTS := $(addsuffix /support.yml,$(TESTS))

all: _data/support.yml

#
# Remove cached `support.yml` for each test.
#
clean:
	$(RM) $(TESTS)

#
# Run all tests and store results.
#
# The AWK trick is to add an empty line between each file.
#
_data/support.yml: $(TESTS)
	awk 'NR != 1 && FNR == 1 { print "" } 1' $^ > $@

#
# Run tests for each supported Sass compiler.
#
# The basename of the target directory will be used as YAML property,
# than all tests will be executed by comparing the input and the
# fixture (`$^` should contain the input file followed by the fixture).
#
# 1. True value.
# 2. False value.
#
# The boolean values are configurable so you can just invert them to run
# an "unexpect" test.
#
test = \
	basename $(@D) | sed 's/$$/:/' > $@; \
	utils/test ruby_sass_3_2 3.2 $^ $(1) $(2) >> $@; \
	utils/test ruby_sass_3_3 3.3 $^ $(1) $(2) >> $@; \
	utils/test ruby_sass_3_4 3.4 $^ $(1) $(2) >> $@; \
	utils/test libsass lib $^ $(1) $(2) >> $@

#
# Test against an expected input (should equals).
#
tests/%/support.yml: tests/%/input.scss tests/%/expect.min.css
	$(call test,true,false)

#
# Test against an unexpected input (should not equals).
#
tests/%/support.yml: tests/%/input.scss tests/%/unexpect.min.css
	$(call test,false,true)

#
# Do not remove `tests/%.min.css` (intermediate) files after execution.
#
.PRECIOUS: tests/%.min.css

#
# How to create a `tests/%.min.css` from a `tests/%.css`.
#
# `$(UGLIFY)` should be built before, but it's not a real dependency
# (hence order-only prerequisite).
#
tests/%.min.css: tests/%.css | $(UGLIFY)
	$(UGLIFY) $< > $@

#
# Install CSS minifier.
#
$(UGLIFY):
	npm install uglifycss
