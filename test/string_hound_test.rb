require File.join(File.dirname(__FILE__), 'test_helper')

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

    should "get rid of lines of pure interpreted erb" do
      s = "<% wombat-loves-oz %>"
      s1 = "<% wombats-snow and other fun\n"
      out = @hound.taste(s)
      assert_equal [], out
    end

    should "parse normally erb lines containing <%=" do
      s = "<%= wombat-loves-oz and 'Cool stuff click' %>"
      out = @hound.taste(s)
      assert_equal ["'Cool stuff click'"], out
    end

    should "parse nested erb inside html" do
      s = "<strong><%= wombat-loves-oz and 'Cool stuff click' %></strong>"
      out = @hound.taste(s)
      assert_equal ["'Cool stuff click'"], out
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

  context "#chew" do
    setup do
      @hound = StringHound.new("test")
      @out_arry = ["wombats are cool", "   "]
    end

    should "get rid of strings that are only whitespace" do
      out = @hound.chew(@out_arry)
      assert_equal ["wombats are cool"], out
    end

    should "get rid of strings that are only digits" do
      @out_arry << "989"
      @out_arry << "more stuff99"
      out = @hound.chew(@out_arry)
      assert_equal ["wombats are cool", "more stuff99"], out
    end

    should "get rid of strings that are possible varaible names, contains no spaces and underscores" do
      @out_arry << "wombat_loves_oz"
      @out_arry << "wombats_snow and other fun"
      out = @hound.chew(@out_arry)
      assert_equal ["wombats are cool", "wombats_snow and other fun"], out
    end

    should_eventually "get rid of strings that are possible varaible names, contains spaces and dashes in one word" do
      @out_arry << "'  wombat-loves-oz'"
      @out_arry << "'wombats-snow and other fun'"
      out = @hound.chew(@out_arry)
      assert_equal ["wombats are cool", "'wombats-snow and other fun'"], out
    end

  end

  context "#digest" do
    setup do
      @hound = StringHound.new("test")
      @f = File.new('test/myfile.txt', "w+")
      #This should work with a stub instead
      #StringHound.any_instance.stubs(:file).returns(f)
      @hound.file = @f
    end

    teardown do
      File.delete(@f.path)
    end

    context "construct i18n string" do
      should "use all text" do
        content = "wombat success hooray"
        s_out, k_out = @hound.digest(content)
        assert_equal "I18n.t('txt.admin.myfile.wombat_success_hooray')", s_out
      end

      should "use ruby variables if present" do
        snow = 'snow'
        content = 'wombat success hooray #{snow}'
        s_out, k_out = @hound.digest(content)
        assert_equal "I18n.t('txt.admin.myfile.wombat_success_hooray_snow', :[\"snow\"] => [\"snow\"])", s_out
      end

    end

    context "construct key" do
      should "use the first five words of the content" do
        content = "wombats all hooray other snowboard stuff"
        s_out, k_out = @hound.digest(content)
        assert_equal "txt.admin.myfile.wombats_all_hooray_other_snowboard", k_out
      end
     end

  end

  context "#speak" do
    setup do
      StringHound.default_yml = "test/myfile.yml"
      @r_file = File.new("test/somefile.rb", "w+")
      @t_file = File.new("test/tfile.rb", "w+")
    end

    teardown do
      File.delete(@r_file.path)
      File.delete(@t_file.path)
      File.delete(StringHound.default_yml) if File.exists?(StringHound.default_yml)
    end

    should "return if command_speak not set" do
      @hound = StringHound.new("test")
      File.any_instance.expects(:write).never
      @hound.speak("peekachoo rules")
    end

    should "write the given line to output file if content_array is empty" do
      @hound = StringHound.new("test")
      @hound.command_speak = true
      @hound.file = @r_file
      out = @hound.taste("99")
      assert_equal [], out

      Tempfile.stubs(:new).returns(@t_file)
      @t_file.expects(:write)
      @hound.speak("  99  ")
    end

    should "add content to yml and source file if content_array exists and not interactive mode" do
      @hound = StringHound.new("test")
      @hound.command_speak = true
      @hound.file = @r_file
      out = @hound.taste("'99 wombats everywhere'")
      assert_equal ["'99 wombats everywhere'"], out

      Tempfile.stubs(:new).returns(@t_file)
      @t_file.expects(:write).at_least_once
      @hound.speak("'99 wombats everywhere'")
    end

  end

  context "#speak_source_file" do
    setup do
      StringHound.default_yml = "test/myfile.yml"
      @r_file = File.new("test/somefile.rb", "w+")
      @t_file = File.new("test/tfile.rb", "w+")
    end

    teardown do
      File.delete(@r_file.path)
      File.delete(@t_file.path)
      File.delete(StringHound.default_yml) if File.exists?(StringHound.default_yml)
    end
  end

end
