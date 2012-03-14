module RegexUtils

  def self.included(base)
    base.class_eval do

      def parse_for_strings(line)
        line.scan(/["'][\w\s#\{\}]*["']/)
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

      def inline_strings(line)
        if @inline && line.match(/^[\s]*(TEXT|CONTENT)/)
          @inline = nil
        elsif @inline || match = line.match(/(<<-TEXT|<<-CONTENT)[\s]*/)
          @inline = true
          match.nil? ? line : match.post_match
        end
      end

      def find_variables(content)
        content.scan(/#\{(\w*)\}/)
      end

    end
  end
end
