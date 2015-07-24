# init_test.rb - Centralizes all needs for running MiniTest
# Copyright (C) 2015 Wolfgang Holoch <wolfgang.holoch@gmail.com>
#
# All testfiles must be inside the "test" folder, named like "test_<name>.rb" and should only require this file (this
# script will load all source code for the testfiles).

# Check if we should generate a coverage report.
if ENV["COVERAGE"]
  require "simplecov"

  SimpleCov.start do
    add_filter "/test/"
    command_name "MiniTest"
    root ENV["COVERAGE_ROOT"]
    coverage_dir ENV["COVERAGE_DIR"]
  end
end

# By requiring this file, every test file runs automatically.
require "minitest/autorun"

# Require all *.rb files inside the src folder.
Dir.glob(File.expand_path("../../src", __FILE__) + "/**/*.rb").each do |file|
  require file
end

# Don't print log messages during a test:
LOG.level = Logger::UNKNOWN

