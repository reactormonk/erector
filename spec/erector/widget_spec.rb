require File.expand_path("#{File.dirname(__FILE__)}/../spec_helper")
require 'benchmark'

module WidgetSpec
  describe Erector::Widget do
    include Erector::Mixin

    describe "#to_s" do
      class << self
        define_method("invokes #content and returns the string representation of the rendered widget") do
          it "invokes #content and returns the string representation of the rendered widget" do
            widget = Erector.inline do
              div "Hello"
            end
            mock.proxy(widget).content
            widget.to_s.should == "<div>Hello</div>"
          end
        end
      end

      context "when passed no arguments" do
        send "invokes #content and returns the string representation of the rendered widget"
      end

      context "when passed an argument that is #content" do
        send "invokes #content and returns the string representation of the rendered widget"
      end

      context "when passed an argument that is not #content" do
        attr_reader :widget
        before do
          @widget = Erector::Widget.new
          def widget.alternate_content
            div "Hello from Alternate Write"
          end
          mock.proxy(widget).alternate_content
        end

        it "invokes the passed in method name and returns the string representation of the rendered widget" do
          widget.to_s(:content_method_name => :alternate_content).should == "<div>Hello from Alternate Write</div>"
        end

        it "does not invoke #content" do
          dont_allow(widget).content
          widget.to_s(:content_method_name => :alternate_content)
        end
      end
      
      it "can accept an existing string as an output buffer" do
        s = "foo"
        Erector.inline { text "bar" }.to_s(:output => s)
        s.should == "foobar"
      end

      it "can accept an existing Output as an output buffer" do
        output = Erector::Output.new
        output << "foo"
        Erector.inline { text "bar" }.to_s(:output => output)
        output.to_s.should == "foobar"
      end
    end

    describe "#to_a" do
      it "returns an array" do
        widget = Erector.inline do
          div "Hello"
        end
        a = widget.to_a
        a.is_a?(Array).should be_true
        a.join.should == "<div>Hello</div>"
      end

    # removing this, since oddly, when i run this test solo it works, but when
    # i run it as part of a rake suite, i get the opposite result -Alex
    #   it "runs faster than using a string as the output" do
    #     widget = Erector.inline do
    #       1000.times do |i|
    #         div "Lorem ipsum dolor sit amet #{i}, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est #{i} laborum."
    #       end
    #     end
    # 
    #     times = 20
    #     time_for_to_a = Benchmark.measure { times.times { widget.to_a } }.total
    #     # puts "to_a: #{time_for_to_a}"
    #     time_for_string = Benchmark.measure { times.times { widget.to_s(:output => "") } }.total
    #     # puts "to_s(''): #{time_for_string}"
    #     
    #     percent_faster = (((time_for_string - time_for_to_a) / time_for_string)*100)
    #     # puts ("%.1f%%" % percent_faster)
    # 
    #     (time_for_to_a <= time_for_string).should be_true
    #   end
    end

    describe '#widget' do
      context "basic nesting" do
        before do
          class Parent < Erector::Widget
            def content
              text 1
              widget Child do
                text 2
                third
              end
            end

            def third
              text 3
            end
          end

          class Child < Erector::Widget
            def content
              super
            end
          end
        end

        it "renders nested widgets in the correct order" do
          Parent.new.to_s.should == '123'
        end
      end
      
      class ::Orphan < Erector::Widget
        def content
          p @name
        end
      end
      
      context "when passed a class" do
        it "renders it" do
          Erector.inline do
            div do
              widget ::Orphan, :name => "Annie"
            end
          end.to_s.should == "<div><p>Annie</p></div>"
        end
      end
      
      context "when passed an instance" do
        it "renders it" do
          Erector.inline do
            div do
              widget ::Orphan.new(:name => "Oliver")
            end
          end.to_s.should == "<div><p>Oliver</p></div>"
        end
      end

        context "when nested" do
          module WhenNested
            class Parent < Erector::Widget
              def content
                div :id => "parent_widget" do
                  super
                end
              end
            end

            class Child < Erector::Widget
              def content
                div :id => "child_widget" do
                  super
                end
              end
            end

            class Grandchild < Erector::Widget
              needs :parent_widget, :child_widget
              def content
                widget(@parent_widget) do
                  widget(@child_widget) do
                    div :id => "grandchild"
                  end
                end
              end            
            end
          end
          
          it "renders the tag around the rest of the block" do
            WhenNested::Grandchild.new(:parent_widget => WhenNested::Parent, 
              :child_widget => WhenNested::Child).to_s.should == '<div id="parent_widget"><div id="child_widget"><div id="grandchild"></div></div></div>'
          end
        
          it "renders the tag around the rest of the block with proper indentation" do
            WhenNested::Grandchild.new(:parent_widget => WhenNested::Parent, :child_widget => WhenNested::Child).to_pretty.should == 
            "<div id=\"parent_widget\">\n" + 
            "  <div id=\"child_widget\">\n" + 
            "    <div id=\"grandchild\"></div>\n" + 
            "  </div>\n" +
            "</div>\n"
          end
        
        it "passes a pointer to the child object back into the parent object's block" do
          child_widget = Erector::Widget.new
          
          class Parent2 < Erector::Widget 
            needs :child_widget
            def content
              div do
                widget @child_widget do |child|
                  b child.dom_id
                end
              end
            end
          end
          
          Parent2.new(:child_widget => child_widget).to_s.should == "<div><b>#{child_widget.dom_id}</b></div>"
          
        end
        
      end
    end
    
    describe "#call_block" do
      it "calls the block with a pointer to self" do
        inside_arg = nil
        inside_self = nil
        x = Erector::Widget.new do |y|
          inside_arg = y.object_id
          inside_self = self.object_id
        end
        x.call_block
        # inside the block...
        inside_arg.should == x.object_id # the argument is the child
        inside_self.should == self.object_id # and self is the parent
      end
    end

    describe '#capture' do
      it "should return content rather than write it to the buffer" do
        widget = Erector.inline do
          captured = capture do
            p 'Captured Content'
          end
          div do
            text captured
          end
        end
        widget.to_s.should == '<div><p>Captured Content</p></div>'
      end

      it "returns a RawString" do
        captured = nil
        Erector.inline do
          captured = capture {}
        end.to_s.should == ""
        captured.should be_a_kind_of(Erector::RawString)
      end

      it "works with nested captures" do
        widget = Erector.inline do
          captured = capture do
            captured = capture do
              p 'Nested Capture'
            end
            p 'Captured Content'
            text captured
          end
          div do
            text captured
          end
        end
        widget.to_s.should == '<div><p>Captured Content</p><p>Nested Capture</p></div>'
      end
    end

    describe 'nested' do
      it "can insert another widget without raw" do
        inner = Erector.inline do
          p "foo"
        end

        outer = Erector.inline do
          div inner
        end.to_s.should == '<div><p>foo</p></div>'
      end
    end

    describe '#write_via' do
      class ::A < Erector::Widget
        def content
          p "A"
        end
      end

      it "renders to a widget's doc" do
        class B < Erector::Widget
          def content
            text "B"
            ::A.new.write_via(self)
            text "B"
          end
        end
        b = B.new
        b.to_s.should == "B<p>A</p>B"
      end

      it "passing a widget to text method renders it" do
        Erector.inline do
          text "B"
          text ::A.new()
          text "B"
        end.to_s.should == "B<p>A</p>B"
      end

    end
    
    describe "assigning instance variables" do
      it "attempting to overwrite a reserved instance variable raises error" do
        lambda {
          Erector::Widget.new(:output => "foo")
        }.should raise_error(ArgumentError)
      end

      it "handles instance variable names with and without '@' in the beginning" do
        html = Erector.inline(:foo => "bar", '@baz' => 'quux') do
          div do
            p @foo
            p @baz
          end
        end.to_s
        doc = Nokogiri::HTML(html)
        doc.css("p").map {|p| p.inner_html}.should == ["bar", "quux"]
      end
    end
  end
end
