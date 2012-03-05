Gem::Specification.new do |s|
  s.name        = 'string_hound'
  s.version     = '0.0.0'
  s.date        = '2012-3-1'
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
     "lib/string_hound/tasks.rb",
     "test/string_hound_test.rb"
  ]
  s.test_files  = ["test/string_hound_test.rb"]
  s.require_paths = [".", 'lib']
end
