require 'string_hound'

desc "Given a directory, traverse through it and output all strings in all files to STDOUT."
namespace :hound do
  task :hunt do
    if ARGV.count < 2
      puts "Incorrect number of arguments.  Please give a directory name"
      return
    end
    dir = ARGV.pop
    hound = StringHound.new(dir)
    hound.hunt
    hound.howl
  end

  desc "Same as hunt, except instead of outputting to STDOUT, 'speak' inserts i18 strings into source files and adds keys to default yml file"
  task :speak do
    if ARGV.count < 2
      puts "Incorrect number of arguments.  Please give a directory name"
      return
    end

    dir = ARGV.pop
    hound = StringHound.new(dir)
    hound.command_speak = true
    hound.hunt
  end

  desc "Same as speak, except instead of inserting diffs directly into file, it asks permission to accept or deny the generated new string"
  task :play do
    if ARGV.count < 2
      puts "Incorrect number of arguments.  Please give a directory name"
      return
    end

    dir = ARGV.pop
    hound = StringHound.new(dir,{:interactive => true})
    hound.command_speak = true
    hound.hunt
  end

end
