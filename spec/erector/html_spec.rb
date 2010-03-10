require File.expand_path("#{File.dirname(__FILE__)}/../spec_helper")

describe Erector::HTML do
  describe ".all_tags" do
    it "returns set of full and empty tags" do
      Erector::Widget.all_tags.class.should == Array
      Erector::Widget.all_tags.should == Erector::Widget.full_tags + Erector::Widget.empty_tags
    end
  end

  describe "#instruct" do
    it "when passed no arguments; returns an XML declaration with version 1 and utf-8" do
      # version must precede encoding, per XML 1.0 4th edition (section 2.8)
      Erector.inline { instruct }.to_s.should == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
    end
  end

  describe "#element" do
    context "when receiving one argument" do
      it "returns an empty element" do
        Erector.inline do
          element('div')
        end.to_s.should == "<div></div>"
      end
    end

    context "with a attribute hash" do
      it "returns an empty element with the attributes" do
        html = Erector.inline do
          element(
            'div',
            :class => "foo bar",
            :style => "display: none; color: white; float: left;",
            :nil_attribute => nil
          )
        end.to_s
        doc = Nokogiri::HTML(html)
        div = doc.at('div')
        div[:class].should == "foo bar"
        div[:style].should == "display: none; color: white; float: left;"
        div[:nil_attribute].should be_nil
      end
    end

    context "with an array of CSS classes" do
      it "returns a tag with the classes separated" do
        Erector.inline do
          element('div', :class => [:foo, :bar])
        end.to_s.should == "<div class=\"foo bar\"></div>";
      end
    end

    context "with an array of CSS classes as strings" do
      it "returns a tag with the classes separated" do
        Erector.inline do
          element('div', :class => ['foo', 'bar'])
        end.to_s.should == "<div class=\"foo bar\"></div>";
      end
    end

    context "with a CSS class which is a string" do
      it "just use that as the attribute value" do
        Erector.inline do
          element('div', :class => "foo bar")
        end.to_s.should == "<div class=\"foo bar\"></div>";
      end
    end

    context "with an empty array of CSS classes" do
      it "does not emit a class attribute" do
        Erector.inline do
          element('div', :class => [])
        end.to_s.should == "<div></div>"
      end
    end

    context "with many attributes" do
      it "alphabetize them" do
        Erector.inline do
          empty_element('foo', :alpha => "", :betty => "5", :aardvark => "tough",
                        :carol => "", :demon => "", :erector => "", :pi => "3.14", :omicron => "", :zebra => "", :brain => "")
        end.to_s.should == "<foo aardvark=\"tough\" alpha=\"\" betty=\"5\" brain=\"\" carol=\"\" demon=\"\" " \
               "erector=\"\" omicron=\"\" pi=\"3.14\" zebra=\"\" />";
      end
    end

    context "with inner tags" do
      it "returns nested tags" do
        widget = Erector.inline do
          element 'div' do
            element 'div'
          end
        end
        widget.to_s.should == '<div><div></div></div>'
      end
    end

    context "with text" do
      it "returns element with inner text" do
        Erector.inline do
          element 'div', 'test text'
        end.to_s.should == "<div>test text</div>"
      end
    end

    context "with object other than hash" do
      it "returns element with inner text == object.to_s" do
        object = 42 # ['a', 'b'] does not work since 1.9 goes like '["a", "b"]' and erector escapes that as well
        Erector.inline do
          element 'div', object
        end.to_s.should == "<div>#{object.to_s}</div>"
      end
    end

    context "with parameters and block" do
      it "returns element with inner html and attributes" do
        Erector.inline do
          element 'div', 'class' => "foobar" do
            element 'span', 'style' => 'display: none;'
          end
        end.to_s.should == '<div class="foobar"><span style="display: none;"></span></div>'
      end
    end

    context "with content and parameters" do
      it "returns element with content as inner html and attributes" do
        Erector.inline do
          element 'div', 'test text', :style => "display: none;"
        end.to_s.should == '<div style="display: none;">test text</div>'
      end
    end

    context "with more than three arguments" do
      it "raises ArgumentError" do
        proc do
          Erector.inline do
            element 'div', 'foobar', {}, 'fourth'
          end.to_s
        end.should raise_error(ArgumentError)
      end
    end

    it "renders the proper full tags" do
      Erector::Widget.full_tags.each do |tag_name|
        expected = "<#{tag_name}></#{tag_name}>"
        actual = Erector.inline do
          send(tag_name)
        end.to_s
        begin
          actual.should == expected
        rescue Spec::Expectations::ExpectationNotMetError => e
          puts "Expected #{tag_name} to be a full element. Expected #{expected}, got #{actual}"
          raise e
        end
      end
    end

    describe "quoting" do
      context "when outputting text" do
        it "quotes it" do
          Erector.inline do
            element 'div', 'test &<>text'
          end.to_s.should == "<div>test &amp;&lt;&gt;text</div>"
        end
      end

      context "when outputting text via text" do
        it "quotes it" do
          Erector.inline do
            element 'div' do
              text "test &<>text"
            end
          end.to_s.should == "<div>test &amp;&lt;&gt;text</div>"
        end
      end

      context "when outputting attribute value" do
        it "quotes it" do
          Erector.inline do
            element 'a', :href => "foo.cgi?a&b"
          end.to_s.should == "<a href=\"foo.cgi?a&amp;b\"></a>"
        end
      end

      context "with raw text" do
        it "does not quote it" do
          Erector.inline do
            element 'div' do
              text raw("<b>bold</b>")
            end
          end.to_s.should == "<div><b>bold</b></div>"
        end
      end

      context "with raw text and no block" do
        it "does not quote it" do
          Erector.inline do
            element 'div', raw("<b>bold</b>")
          end.to_s.should == "<div><b>bold</b></div>"
        end
      end

      context "with raw attribute" do
        it "does not quote it" do
          Erector.inline do
            element 'a', :href => raw("foo?x=&nbsp;")
          end.to_s.should == "<a href=\"foo?x=&nbsp;\"></a>"
        end
      end

      context "with quote in attribute" do
        it "quotes it" do
          Erector.inline do
            element 'a', :onload => "alert(\"foo\")"
          end.to_s.should == "<a onload=\"alert(&quot;foo&quot;)\"></a>"
        end
      end
    end

    context "with a non-string, non-raw" do
      it "calls to_s and quotes" do
        Erector.inline do
          element 'a' do
            text(:answer => 42)
          end
        end.to_s.should == "<a>{:answer=&gt;42}</a>"
      end
    end
  end

  describe "#empty_element" do
    context "when receiving attributes" do
      it "renders an empty element with the attributes" do
        Erector.inline do
          empty_element 'input', :name => 'foo[bar]'
        end.to_s.should == '<input name="foo[bar]" />'
      end
    end

    context "when not receiving attributes" do
      it "renders an empty element without attributes" do
        Erector.inline do
          empty_element 'br'
        end.to_s.should == '<br />'
      end
    end

    it "renders the proper empty-element tags" do
      Erector::Widget.empty_tags.each do |tag_name|
        expected = "<#{tag_name} />"
        actual = Erector.inline do
          send(tag_name)
        end.to_s
        begin
          actual.should == expected
        rescue Spec::Expectations::ExpectationNotMetError => e
          puts "Expected #{tag_name} to be an empty-element tag. Expected #{expected}, got #{actual}"
          raise e
        end
      end
    end
  end

  describe "#comment" do
    it "emits a single line comment when receiving a string" do
      Erector.inline do
        comment "foo"
      end.to_s.should == "<!--foo-->\n"
    end

    it "emits a multiline comment when receiving a block" do
      Erector.inline do
        comment do
          text "Hello"
          text " world!"
        end
      end.to_s.should == "<!--\nHello world!\n-->\n"
    end

    it "emits a multiline comment when receiving a string and a block" do
      Erector.inline do
        comment "Hello" do
          text " world!"
        end
      end.to_s.should == "<!--Hello\n world!\n-->\n"
    end

    # see http://www.w3.org/TR/html4/intro/sgmltut.html#h-3.2.4
    it "does not HTML-escape character references" do
      Erector.inline do
        comment "&nbsp;"
      end.to_s.should == "<!--&nbsp;-->\n"
    end

    def capturing_output
      output = StringIO.new
      $stdout = output
      yield
      output.string
    ensure
      $stdout = STDOUT
    end

    # see http://www.w3.org/TR/html4/intro/sgmltut.html#h-3.2.4
    # "Authors should avoid putting two or more adjacent hyphens inside comments."
    it "warns if there's two hyphens in a row" do
      capturing_output do
        Erector.inline do
          comment "he was -- awesome!"
        end.to_s.should == "<!--he was -- awesome!-->\n"
      end.should == "Warning: Authors should avoid putting two or more adjacent hyphens inside comments.\n"
    end

    it "renders an IE conditional comment with endif when receiving an if IE" do
      Erector.inline do
        comment "[if IE]" do
          text "Hello IE!"
        end
      end.to_s.should == "<!--[if IE]>\nHello IE!\n<![endif]-->\n"
    end

    it "doesn't render an IE conditional comment if there's just some text in brackets" do
      Erector.inline do
        comment "[puppies are cute]"
      end.to_s.should == "<!--[puppies are cute]-->\n"
    end

  end

  describe "#nbsp" do
    it "turns consecutive spaces into consecutive non-breaking spaces" do
      Erector.inline do
        text nbsp("a  b")
      end.to_s.should == "a&#160;&#160;b"
    end

    it "works in text context" do
      Erector.inline do
        element 'a' do
          text nbsp("&<> foo")
        end
      end.to_s.should == "<a>&amp;&lt;&gt;&#160;foo</a>"
    end

    it "works in attribute value context" do
      Erector.inline do
        element 'a', :href => nbsp("&<> foo")
      end.to_s.should == "<a href=\"&amp;&lt;&gt;&#160;foo\"></a>"
    end

    it "defaults to a single non-breaking space if given no argument" do
      Erector.inline do
        text nbsp
      end.to_s.should == "&#160;"
    end

  end

  describe "#character" do
    it "renders a character given the codepoint number" do
      Erector.inline do
        text character(160)
      end.to_s.should == "&#xa0;"
    end

    it "renders a character given the unicode name" do
      Erector.inline do
        text character(:right_arrow)
      end.to_s.should == "&#x2192;"
    end

    it "renders a character above 0xffff" do
      Erector.inline do
        text character(:old_persian_sign_ka)
      end.to_s.should == "&#x103a3;"
    end

    it "throws an exception if a name is not recognized" do
      lambda {
        Erector.inline do
          text character(:no_such_character_name)
        end.to_s
      }.should raise_error("Unrecognized character no_such_character_name")
    end

    it "throws an exception if passed something besides a symbol or integer" do
      # Perhaps calling to_s would be more ruby-esque, but that seems like it might
      # be pretty confusing when this method can already take either a name or number
      lambda {
        Erector.inline do
          text character([])
        end.to_s
      }.should raise_error(/Unrecognized argument to character: /)
    end
  end

  describe '#h' do
    before do
      @widget = Erector::Widget.new
    end

    it "escapes regular strings" do
      @widget.h("&").should == "&amp;"
    end

    it "does not escape raw strings" do
      @widget.h(@widget.raw("&")).should == "&"
    end
  end

  describe 'escaping' do
    plain = 'if (x < y && x > z) alert("don\'t stop");'
    escaped = "if (x &lt; y &amp;&amp; x &gt; z) alert(&quot;don't stop&quot;);"

    describe "#text" do
      it "does HTML escape its param" do
        Erector.inline { text plain }.to_s.should == escaped
      end

      it "doesn't escape pre-escaped strings" do
        Erector.inline { text h(plain) }.to_s.should == escaped
      end
    end
    describe "#rawtext" do
      it "doesn't HTML escape its param" do
        Erector.inline { rawtext plain }.to_s.should == plain
      end
    end
    describe "#text!" do
      it "doesn't HTML escape its param" do
        Erector.inline { text! plain }.to_s.should == plain
      end
    end
    describe "#element" do
      it "does HTML escape its param" do
        Erector.inline { element "foo", plain }.to_s.should == "<foo>#{escaped}</foo>"
      end
    end
    describe "#element!" do
      it "doesn't HTML escape its param" do
        Erector.inline { element! "foo", plain }.to_s.should == "<foo>#{plain}</foo>"
      end
    end
  end

  describe "#javascript" do
    context "when receiving a block" do
      it "renders the content inside of script text/javascript tags" do
        expected = <<-EXPECTED
          <script type="text/javascript">
          // <![CDATA[
          if (x < y && x > z) alert("don't stop");
          // ]]>
          </script>
        EXPECTED
        expected.gsub!(/^          /, '')
        Erector.inline do
          javascript do
            rawtext 'if (x < y && x > z) alert("don\'t stop");'
          end
        end.to_s.should == expected
      end
    end

    it "renders the raw content inside script tags when given text" do
      expected = <<-EXPECTED
        <script type="text/javascript">
        // <![CDATA[
        alert("&<>'hello");
        // ]]>
        </script>
      EXPECTED
      expected.gsub!(/^        /, '')
      Erector.inline do
        javascript('alert("&<>\'hello");')
      end.to_s.should == expected
    end

    context "when receiving a params hash" do
      it "renders a source file" do
        html = Erector.inline do
          javascript(:src => "/my/js/file.js")
        end.to_s
        doc = Nokogiri::HTML(html)
        doc.at("script")[:src].should == "/my/js/file.js"
      end
    end

    context "when receiving text and a params hash" do
      it "renders a source file" do
        html = Erector.inline do
          javascript('alert("&<>\'hello");', :src => "/my/js/file.js")
        end.to_s
        doc = Nokogiri::HTML(html)
        script_tag = doc.at('script')
        script_tag[:src].should == "/my/js/file.js"
        script_tag.inner_html.should include('alert("&<>\'hello");')
      end
    end

    context "with too many arguments" do
      it "raises ArgumentError" do
        proc do
          Erector.inline do
            javascript 'foobar', {}, 'fourth'
          end.to_s
        end.should raise_error(ArgumentError)
      end
    end
  end

  describe "#close_tag" do
    it "works when it's all alone, even though it messes with the indent level" do
      Erector.inline { close_tag :foo }.to_s.should == "</foo>"
      Erector.inline { close_tag :foo; close_tag :bar }.to_s.should == "</foo></bar>"
    end
  end
end
