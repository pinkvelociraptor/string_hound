require 'string_hound'

desc "Given a directory, traverse through it and output all strings in all files"
task :hunt do
  dir = ARGV.shift
  hound = StringHound.new(dir)
  hound.hunt
end
