require "minitest/unit"
require "rdoc/rdoc"


DIR = File.expand_path "..", __FILE__
DIR_SRC = "#{DIR}/src"
DIR_TEST = "#{DIR}/test"

DIR_COV = "#{DIR}/coverage"
DIR_RDOC = "#{DIR}/doc"

RDOC_OPTS = ["-c", "UTF-8", "-o", DIR_RDOC]


desc "Remove all generated files."
task :clean => ["rdoc:clean", "test:clean"]

desc "Build RDoc documentation and run all tests."
task :default => ["rdoc", "test"]

desc "Build RDoc dev documentation, run all tests and generate a coverage report."
task :dev => ["rdoc:dev", "test:coverage"]

desc "Build RDoc documentation files."
task :rdoc => "rdoc:default"

desc "Run all tests of this project."
task :test => "test:default"


namespace :rdoc do

  desc "Remove all RDoc documentation files."
  task :clean do
    rm_r DIR_RDOC if File.directory? DIR_RDOC
    rm Dir.glob("#{DIR_SRC}/**/*_rb.html")
  end

  task :default do
    RDoc::RDoc.new.document(RDOC_OPTS + [DIR_SRC])
  end

  desc "Build RDoc documentation files (include private and protected methods/attributes)."
  task :dev do
    RDoc::RDoc.new.document(RDOC_OPTS + ["-a", DIR_SRC])
  end

  desc "Force rebuild of RDoc documentation files."
  task :force do
    RDoc::RDoc.new.document(RDOC_OPTS + ["--force-update", "-O", DIR_SRC])
  end
end


namespace :test do

  desc "Remove all coverage files."
  task :clean do
    rm_r DIR_COV if File.directory? DIR_COV
  end

  task :default do
    Dir.glob("#{DIR_TEST}/**/test_*.rb").each {|file| require file}
  end

  desc "Run all tests of this project and generate a coverage report."
  task :coverage do
    ENV["COVERAGE"] = "true"
    ENV["COVERAGE_ROOT"] = File.dirname DIR_COV
    ENV["COVERAGE_DIR"] = File.basename DIR_COV
    Rake::Task["test:default"].execute
  end
end

