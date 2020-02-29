require "skellie/sketch/attribute"
require "active_support/core_ext/string/inflections"

module Skellie
  module Parser
    class Attribute
      class Empty
        def self.===(object)
          !object || ("" == object)
        end
      end

      VALID_TYPE_MODIFIER_KEYS = %i[thru class as poly]
      VALID_ASSOCIATION_MODIFIER_KEYS = %i[thru class as poly]
      class UnknownType < StandardError; end
      class ParseError < StandardError; end

      attr_accessor :input
      def initialize(input)
        @input = input
      end

      def parse
        output = Skellie::Sketch::Attribute.new
        # puts "output: #{output.inspect}"
        case input
        when String
          # puts "input is a string"
          s = StringScanner.new(input)
          parse_op_and_name(s, output)
          parse_type(s.rest, output)
        when Hash
          if input.length == 1
            name = input.first.first
            type = input.first.last
            s = StringScanner.new(name)
            parse_op_and_name(s, output)
            raise ParseError, "invalid attribute name `#{name}` in `#{input.inspect}`" unless s.eos?
            parse_type(type, output)
          elsif input.has_key?(:name)
            validate_modifier_keys
            s = StringScanner.new(input[:name])
            parse_op_and_name(s, output)
            raise ParseError, "invalid attribute name `#{input[:name]}` in `#{input.inspect}`" unless s.eos?
            parse_type(input, output)
          else
            raise ParseError, "can't parse #{input.inspect} (no name and more than one key)"
          end
          output
        end

        puts "returning output: #{output}"
        output
      end

      def parse_op_and_name(s, output)
        output.kind = scan_op(s)
        scan_namespace_and_name(s, output)
      end

      def scan_op(s)
        case s.scan(/[+~]?/)
        when "+"
          :association
        when "~"
          :remove_column
        else
          :add_column
        end
      end

      def scan_namespace_and_name(s, output)
        s.scan(
          %r{
            (?<namespace>\w+(?=/))?
            /?
            (?<name>\w+)
            (?:>(?<new_name>\w+))?
            :?
          }x
        )
        output.namespace = s[:namespace]
        if output.namespace && output.kind != :association
          raise ParseError, "can't give column a namespace `#{output.namespace}` in `#{input.inspect}`"
        end
        output.name = s[:name]
        if s[:new_name]
          output.kind = :rename_column
          output.new_name = s[:new_name]
        end
      end

      def scan_modifiers(s, output)
        case output.kind
        when :association
          scan_association unless s.eos?
        when :remove_column
        when :add_column
          scan_type(s)
        end
      end

      def parse_type(type_and_modifiers, output)
        case type_and_modifiers
        when Empty
          output.type = case output.kind
          when :add_column
            :string
          end
        when String
          parts = type_and_modifiers.split(":")
          output.type = expand_type(parts.first.to_sym)
        when Hash
          if type.length == 1
            output.type = modifiers.first.first
            output.modifiers = modifiers.first.last
          end
        end
      end

      def scan_type(s)
        return :string if s.eos?
        s.scan(
          %r{
            :
            (?<type>\w+)
            (?<type_modifier>\{\w*\})?
          }x
        )
        return :string unless s[:type]
        expand_type(s[:type])
      end

      def expand_type(type)
        column_types = Skellie.config[:models][:type_aliases]
        type_alias = column_types.detect { |column_type, aliases|
          column_type == type.to_sym || aliases&.include?(type.to_sym)
        }
        raise UnknownType, "unknown type #{type} in `#{input}`" if type_alias.nil?

        type_alias.first.to_sym
      end

      def validate_modifier_keys(modifier)
        valid_keys = VALID_MODIFIER_KEYS
          .merge(Skellie.model_attribute_type_aliases)
          .merge(Skellie.model_attribute_modifier_aliases)

        unknown = modifier.keys - valid_keys
        if unknown.length > 1
          raise ParseError,
            "unknown #{"key".pluralize(unknown.length)}  `#{unknown.inspect}` in #{modifier.inspect}"
        end
      end
    end
  end
end
