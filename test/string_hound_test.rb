require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'mocha'
require 'string_hound'
require 'ruby-debug'

class StringHoundTest < Test::Unit::TestCase

  context "#taste" do
    setup do
      @hound = StringHound.new("test")
    end

    should "find single quoted strings" do
      s = "'single string quoted stuff'"
      out = @hound.taste(s)
      assert_equal ["'single string quoted stuff'"], out
    end

    should "find double quoted strings" do
      s = '"double string stuff"'
      out = @hound.taste(s)
      assert_equal ['"double string stuff"'], out
    end

    should "find strings with embeded ruby variables" do
      var= "foo"
      s = "'i have a ruby #{var} variable'"
      out = @hound.taste(s)
      assert_equal ["'i have a ruby #{var} variable'"], out
    end

    should "find concatinated strings" do
      s = '"Hi there" + "stuff" + "more stuff"'
      out = @hound.taste(s)
      assert_equal ['"Hi there"', '"stuff"', '"more stuff"'], out
    end

    should "ignore strings inside html code" do
      @hound.stubs(:view_file).returns(true)
      s = '<div class="wombat class">'
      out = @hound.taste(s)
      assert_equal [],  out
    end

    should "return nil if no strings found" do
      s = 'Hi and how are you'
      out = @hound.taste(s)
      assert_equal [], out
    end

  end

  context "#inline_strings" do
    setup do
      @hound = StringHound.new("test")
    end

    should "find strings within <<-TEXT tags" do
      s = '<<-TEXT  Some stuff here in text'
      out = @hound.inline_strings(s)
      assert_equal 'Some stuff here in text', out

      s1 = 'more text'
      out = @hound.inline_strings(s1)
      assert_equal 'more text', out

      s2 = "\tTEXT"
      out = @hound.inline_strings(s2)
      assert_nil out
    end

    should "return nil if not a inline string" do
      s = "hi there how are you"
      out = @hound.inline_strings(s)
      assert_nil out
    end
  end
end
