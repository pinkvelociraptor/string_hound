require 'tempfile'
require 'find'
require 'nokogiri'
require 'fileutils'

##
#
#
# Given a directory, StringHound recursively searches the directory
# heirarchy looking for any hardcoded strings.  When found, it prints them
# to standard out in the form:
#   <filename>: <line>    <string value>
#
# In speak mode, Stringhound will also insert a suggested i18n conversion of
# all strings it finds into the file it finds them in, as well as
# insert the same key and translation into the default yml file
##

class StringHound

  attr_reader :view_file
  attr_accessor :file, :command_speak

  class << self; attr_accessor  :default_yml end
  @default_yml = "config/locales/translations/admin.yml"


  def initialize(dir)
    @directory = dir
    @prize = []
    @command_speak = false
  end

#  def command_speak=(set_speak)
#    @command_speak = set_speak
#    @yml_file = File.open("config/locales/translations/admin.yml", "a+")
#  end

  #
  # Iterates through directory and sets up
  # current file to hunt through.
  # Close yml_file if speak was enabled
  #
  def hunt
    Find.find(@directory) do |f|
      unless FileTest.directory?(f)
        @file = File.open(f, "r")
        @view_file = ['.html', '.erb'].include?(File.extname(f))
        sniff
        @file.close if !@file.closed?
      end
    end
    @yml_file.close if @yml_file
  end


  #
  # Grabs content line by line from file and
  # parses it.
  # If speak is enabled, cleanup associated files
  # after it runs
  #
  def sniff
    @file.each_line do |l|
      taste(l)
      @content_arry.each { |m| @prize << {:filename => @file.path, :line_number => @file.lineno, :value => m } }
      speak(l)
    end

    file_cleanup
  end

  #
  # Parse engine
  #
  def taste(line)
    @content_arry = out = []

    if view_file
      return if is_erb_txt(line)
      return if is_javascript(line)

      if m = is_printed_erb(line)
        out = m[0].scan(/["'][\w\s#\{\}]*["']/)
      else
        result = Nokogiri::HTML(line)
        out = result.text().empty? ? out : result.text()
      end
    elsif result = inline_strings(line)
      out = result
    else
      out = line.scan(/["'][\w\s#\{\}]*["']/)
    end

    @content_arry = chew(out)
  end



 #
 # Get rid of strings that are only whitespace, only digits, or are variable names
 # e.g. wombat_love_id, 55, ''
 #
  def chew(prsd_arry)
    prsd_arry.select do |parsed_string|
      parsed_string.match(/[\S]/) &&
        parsed_string.match(/[\D]/)  &&
        !(parsed_string.match(/[\s]/).nil? && parsed_string.match(/[_-]/))
    end
  end



  #
  # Take each piece of found content, search
  # it for embedded variables, construct a new key
  # for the content line and an i18n call for the new content.
  # Key's mainword is longest word of the string
  #
  # Returns:
  #   localized_string = I18n.t('txt.admin.file_path.success', :organization => organization)
  #   key              = txt.admin.file_path.success
  #
  def digest(content)
    matched_vars = content.scan(/#\{(\w*)\}/)
    vars = matched_vars unless matched_vars.nil?

    cur_path = @file.path.split('/',2).last
    cur_path = cur_path.split('.').first
    cur_path.gsub!('/','.')

    words = content.scan(/\w*/)
    words.sort! {|x,y| x.length <=> y.length}
    identifier = words.last

    key_name = "txt.admin." + cur_path + '.' + identifier
    localized_string = "I18n.t('#{key_name}'"

    if vars
      vars.each { |v| localized_string << ", :#{v} => #{v}" }
    end
    localized_string << ")"

    return localized_string, key_name
  end


  #
  # If content is present, generate 18n for it and add it to tmp
  # source file and yml file.
  # Othewise pass through original txt
  # to tmp file.
  #
  def speak(line)
    return unless @command_speak

    f_name = File.basename(@file.path)
    @tmp_file ||= Tempfile.new(f_name)
    @yml_file ||= File.open(self.class.default_yml, "a+")

    if !@content_arry.empty?
      replacement_arry=[]
      @content_arry.each do |content|
        i18n_string, key_name = digest(content)
        replacement_arry << [i18n_string, content]
        speak_yml(content, key_name)
      end

      speak_source_file(line, replacement_arry)
    else
      @tmp_file.write(line)
    end
  end



  #
  # Construct a diff like format in tmp file
  # for i18n string
  #
  def speak_source_file(line, replacement_arry)
    localized_line = line.dup
    replacement_arry.each do |i18n_string, content|
      localized_line.gsub!(content, i18n_string)
    end

    @tmp_file.write("<<<<<<<<<<\n")
    @tmp_file.write("#{localized_line}\n")
    @tmp_file.write("==========\n")
    @tmp_file.write(line)
    @tmp_file.write(">>>>>>>>>>\n")
  end



  #
  # Add translation key to yml file
  #
  def speak_yml(content, key_name)
    # Strip content of it's quotes
    quoteless_content = content.gsub(/["']/,'')
    yml_string  = "  - translation:\n"
    yml_string << "      key: \"#{key_name}\"\n"
    yml_string << "      title: \"#{quoteless_content} label\"\n"
    yml_string << "      value: \"#{quoteless_content}\"\n"

   @yml_file.write("\n<<<<<<<<<<\n")
   @yml_file.write(yml_string)
   @yml_file.write(">>>>>>>>>>\n")
  end



  #
  # Print matches to STDOUT
  #
  def howl
    @prize.each { |p| puts "#{p[:filename]} : #{p[:line_number]}\t\t #{p[:value]}" }
  end

  #
  # Deal with weirdo injected strings in ruby code
  #
  def inline_strings(line)
    if @inline && line.match(/^[\s]*(TEXT|CONTENT)/)
      @inline = nil
    elsif @inline || match = line.match(/(<<-TEXT|<<-CONTENT)[\s]*/)
      @inline = true
      match.nil? ? line : match.post_match
    end
  end

  #
  # Close all files and rename tmp file to real source file
  #
  def file_cleanup
    if @tmp_file
      @tmp_file.close
      FileUtils.mv(@tmp_file.path, @file.path)
      @tmp_file = nil
    end
  end

  def is_erb_txt(line)
    line.match(/<%=/).nil? && line.match(/(<%|%>)/)
  end

  def is_javascript(line)
    line.match(/(\$j|\$z|function)/)
  end

  def is_printed_erb(line)
    line.match(/<%=.*?(\n|%>)/)
  end

end
