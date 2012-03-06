require 'find'
require 'nokogiri'

##
# Given a directory, StringHound recursively searches the directory
# heirarchy looking for any hardcoded strings.  When found, it prints them
# to standard out in the form:
#   <filename>: <line>    <string value>
#
# If no directory is given, StringHound will search the default_leash dir.
# This default behavior can be set via the set_leash rake task
##

class StringHound

  attr_reader :view_file
  class << self; attr_accessor :default_leash end
  @default_leash = "app"

  def initialize(dir = nil)
    @directory = dir.present? ? dir : self.class.default_leash
    @prize = []
  end

  def hunt
    Find.find(@directory) do |f|
      unless FileTest.directory?(f)
        @file = f
        @view_file = ['.html', '.erb'].include?(File.extname(f))
        sniff
      end
    end
    howl
  end

  def sniff
    File.readlines(@file).each_with_index do |l, line_num|
      match = taste(l)
      match.each do |m|
        if m =~ /[\w]/
          @prize << {:filename => @file, :line_number => line_num, :value => m}
        end
      end
    end
  end

  def taste(line)
    out = []
    if view_file
      result = Nokogiri::HTML(line)
      out = result.text().empty? ? out : result.text()
    elsif result = inline_strings(line)
      out = result
    else
      out = line.scan(/["'][\w\s#\{\}]*["']/)
    end
  end

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
