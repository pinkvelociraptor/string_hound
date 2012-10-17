module RegexUtils

  def parse_for_strings(line)
    line.scan(/["'][\w\s#\{\}]*["']/)
  end

  def erb_txt?
    !!content.match(/<%=/).nil? && line.match(/(<%|%>)/)
  end

  def javascript?
    !!content.match(/(\$j|\$z|function)/)
  end

  def find_printed_erb
    content.match(/<%=.*?(\n|%>)/)
  end

  def inline_strings
    if @inline && context.match(/^[\s]*(TEXT|CONTENT)/)
      @inline = nil
    elsif @inline || match = context.match(/(<<-TEXT|<<-CONTENT)[\s]*/)
      @inline = true
      match.nil? ? context : match.post_match
    end
  end

  def self.find_variables_in(valid_string)
    valid_string.scan(/#\{(\w*)\}/)
  end

end
