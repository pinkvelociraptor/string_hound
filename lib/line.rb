class Line

  include RegexUtils

  attr_accessor :raw_html, :content, :valid_strings

  def initialize(content)
    @content = content
    @raw_html = false
    @valid_strings = []
  end

  def is_raw_html?
    @raw_html
  end

end
