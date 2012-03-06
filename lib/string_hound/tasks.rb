require 'string_hound'

desc "Given a directory, traverse through it and output all strings in all files. Searches DEFAULT_DIR directory if none given"
task :hunt do
  dir = ARGV.count < 2 ? nil : ARGV.pop
  hound = StringHound.new(dir)
  hound.hunt
end

desc "Change the default directory StringHound will hunt through if given no arguments"
task :set_leash do
  if ARGV.count < 2
    puts "Incorrect number of arguments. Please give a directory name"
  else
    StringHound.default_leash = ARGV.pop
    puts "Leash is now #{StringHound.default_leash}"
  end
end
