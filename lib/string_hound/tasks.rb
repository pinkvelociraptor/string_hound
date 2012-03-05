require 'string_hound'

desc "Given a directory, traverse through it and output all strings in all files. Use current direcotry if one isn't given"
task :hunt do
  dir = '.' if ARGV.count < 2 ? '.' : ARGV.pop
  hound = StringHound.new(dir)
  hound.hunt
end
