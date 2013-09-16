require 'rubygems'
require 'bundler/setup'
Bundler.require(:test)
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__)))                      # test
$LOAD_PATH.unshift(File.expand_path(File.join(File.dirname(__FILE__), '../lib'))) # lib

require 'test/unit'
require 'shoulda'
require 'mocha/setup'
require 'string_hound'

begin
  require 'ruby-debug'
rescue LoadError
end
