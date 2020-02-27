module Skellie
  module Sketch
    class Model

      attr_accessor :h
      def initialize(opts)
        @h = opts
      end

    end
    
    class Attribute
      attr_accessor :str
      def initialize(str)
        @str = str.strip
        parse
      end

      def parse
        parts = str.split(/ *: */)

      end
    end
  end
