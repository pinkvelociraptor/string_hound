require 'find'
require 'nokogiri'

##
# Given a directory, StringHound recursively searches the directory
# heirarchy looking for any hardcoded strings.  When found, it prints them
# to standard out in the form <filename>: <line>    <string value>
#
# This handles rather simple strings for now, not including
# strings formed with CONTENT>> magic or multiline strings
##

class StringHound

  attr_reader :view_file

  def initialize(dir)
    @directory = dir
    @prize = []
  end

  def hunt
    Find.find(@directory) do |f|
      unless File.directory?(f)
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
      match.each {|m| @prize << {:filename => @file, :line_number => line_num, :value => m}}
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
