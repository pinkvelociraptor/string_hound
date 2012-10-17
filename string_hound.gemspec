Gem::Specification.new do |s|
  s.name        = 'string_hound'
  s.version     = '0.1.5'
  s.platform    = Gem::Platform::RUBY
  s.summary     = "string_hound"
  s.description = "Bark! hunts for strings."
  s.authors     = ["Noel Dellofano"]
  s.email       = 'noel@zendesk.com'
  s.homepage    = 'http://github.com/pinkvelociraptor/string_hound'

  s.files       = [
     "README",
     "Rakefile",
     "string_hound.gemspec",
     "lib/string_hound.rb",
     "lib/regex_utils.rb",
     "lib/string_hound/tasks.rb",
     "test/string_hound_test.rb",
     "test/test_helper.rb"
  ]
  s.test_files  = ["test/string_hound_test.rb"]
  s.require_paths = [".", 'lib']

  s.add_development_dependency("rake")
  s.add_development_dependency("bundler")
  s.add_development_dependency("shoulda")
  s.add_development_dependency("nokogiri")

end
