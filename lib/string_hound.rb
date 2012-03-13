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
# If no directory is given, StringHound will search the default_leash dir.
# This default behavior can be set via the set_leash rake task
#
#
##

class StringHound

  attr_reader :view_file
  attr_accessor :file

  class << self; attr_accessor :default_leash, :default_yml end
  @default_leash = "app"
  @default_yml = "config/locales/translations/admin.yml"


  def initialize(command_speak, dir = nil)
    @directory = dir ? dir : self.class.default_leash
    @prize = []
    @command_speak = command_speak || false
    @yml_file = File.open(self.class.default_yml, "a+") if @command_speak
  end


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

    if @command_speak && @tmp_file
      @tmp_file.close
      FileUtils.mv(@tmp_file.path, @file.path)
    end
  end

  #
  # Parse engine
  #
  def taste(line)
    out = []
    if view_file
      #handle erb
      return @content_arry = [] if ( line.match(/<%=/).nil? && line.match(/(<%|%>)/) )
      if m = line.match(/<%=.*?(\n|%>)/)
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


    #Strip the leading defalt directory from the name for prettier path
    cur_path = @file.path.match(self.class.default_leash).nil? ? @file.path : @file.path.split('/',2).last

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
      @content_arry.each do |content|
        i18n_string, key_name = digest(content)
        speak_yml(content, key_name)
        speak_source_file(i18n_string, line)
      end
    else
      @tmp_file.write(line)
    end
  end



  #
  # Construct a diff like format in tmp file
  # for i18n string
  #
  def speak_source_file(i18n_string, line)
    @tmp_file.write("<<<<<<<<<<\n")
    @tmp_file.write("#{i18n_string}\n")
    @tmp_file.write("==========\n")
    @tmp_file.write(line)
    @tmp_file.write(">>>>>>>>>>\n")
  end



  #
  # Add translation key to yml file
  #
  def speak_yml(content, key_name)
    yml_string  = "  - translation:\n"
    yml_string << "      key: \"#{key_name}\"\n"
    yml_string << "      title: \"#{content} label\"\n"
    yml_string << "      value: \"#{content}\"\n"

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


  def inline_strings(line)
    if @inline && line.match(/^[\s]*(TEXT|CONTENT)/)
      @inline = nil
    elsif @inline || match = line.match(/(<<-TEXT|<<-CONTENT)[\s]*/)
      @inline = true
      match.nil? ? line : match.post_match
    end
  end

end
