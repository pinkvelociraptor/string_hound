require 'rubygems'
require 'bundler/setup'
Bundler.require(:test)
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__)))                      # test
$LOAD_PATH.unshift(File.expand_path(File.join(File.dirname(__FILE__), '../lib'))) # lib

require 'test/unit'
require 'shoulda'
require 'mocha'
require 'string_hound'
require 'ruby-debug'
