module Skellie
  module Sketch
    class Attribute
      class UnknownType < StandardError; end
      class ParseError < StandardError; end

      attr_accessor :str
      attr_accessor :name, :kind, :type, :namespace
      def initialize(str)
        @str = str.strip
        parse
      end

      def parse
        s = StringScanner.new(str)
        scan_op(s)
        scan_namespace_and_name(s)
        scan_type(s) unless s.eos?
      end

      def scan_op(s)
        @kind = case s.scan(/[+~]?/)
        when "+"
          :association
        when "~"
          :remove_column
        else
          :add_column
        end
      end

      def scan_namespace_and_name(s)
        s.scan(
          %r{
            (?<namespace>\w+(?=/))?
            /?
            (?<name>\w+)
          }x
        )
        @namespace = s[:namespace]
        if namespace && kind != :association
          raise ParseError, "can't give column a namespace `#{namespace}` in `#{str}`"
        end
        @name = s[:name]
      end

      def scan_type(s)
        s.scan(
          %r{
            :
            (?<type>\w+)
          }x
        )
        if s[:type]
          column_types = Skellie.config[:models][:type_aliases]
          type_alias = column_types.detect { |column_type, aliases|
            column_type == s[:type].to_sym || aliases&.include?(s[:type])
          }
          raise UnknownType, "unknown type #{s[:type]} in `#{str}`" if type_alias.nil?
          @type = type_alias.first.to_sym
        end
      end
    end
  end
end
