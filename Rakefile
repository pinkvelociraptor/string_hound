require 'rubygems'
require "bundler"
Bundler.setup
require 'rake'
Bundler::GemHelper.install_tasks :name => 'string_hound'

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/*_test.rb'
  test.verbose = true
end

task :default => :test
