require 'string_hound'

desc "Given a directory, traverse through it and output all strings in all files to STDOUT. Searches DEFAULT_DIR directory if none given"
namespace :hound do
  task :hunt do
    dir = ARGV.count < 2 ? nil : ARGV.pop
    hound = StringHound.new(false, dir)
    hound.hunt
    hound.howl
  end

  desc "Same as hunt, except instead of outputting to STDOUT, 'speak' inserts i18 strings into source files and adds keys to default yml file"
  task :speak do
    dir = ARGV.count < 2 ? nil : ARGV.pop
    hound = StringHound.new(true, dir)
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
end
