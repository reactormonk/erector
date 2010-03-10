module Erector
  class Output
    SPACES_PER_INDENT = 2

    attr_reader :prettyprint, :buffer, :widgets
    
    def initialize(options = {})
      options = {:prettyprint => Widget.prettyprint_default}.merge(options)
      @prettyprint = options[:prettyprint]
      @indentation = options[:indentation] || 0
      @buffer = options[:output] || []
      @widgets = []
      @at_line_start = true
    end
    
    def <<(s)
      if prettyprint and at_line_start?
        @buffer << " " * ([@indentation, 0].max * SPACES_PER_INDENT)
      end
      @buffer << s
      @at_line_start = false
      # @at_line_start = @buffer[-1..-1] == "\n" # s[-1..-1] is a clever way to get the last char in a string
      self
    end
    
    def placeholder
      s = ""
      @buffer << s
      s
    end
    
    def to_s
      @buffer.join
    end
    
    def to_a
      @buffer.to_a
    end
    
    def newline
      if prettyprint
        self << "\n" 
        @at_line_start = true
      end
    end
    
    def at_line_start?
      @at_line_start
    end
    
    def indent
      @indentation += 1
    end

    def undent
      @indentation -= 1
    end
  end
end

class String
  alias join to_s
end
