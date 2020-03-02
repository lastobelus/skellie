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
          parse_from_string_parts(output, input)
        when Hash
          puts "parsing from hash"
          if input.length == 1
            op_and_name = input.first.first
            type_and_modifiers = input.first.last
            parse_from_string_parts(output, op_and_name, type_and_modifiers)
          else
            raise ParseError, "can't parse #{input.inspect} (no name and more than one key)"
          end
          output
        end

        puts "returning output: #{output}"
        output
      end

      def parse_from_string_parts(output, op_and_name, rest = nil)
        puts "parse_from_string_parts opt_and_name: #{op_and_name.inspect} rest: #{rest.inspect}"
        s = StringScanner.new(op_and_name)
        parse_op_and_name(s, output)
        type_and_modifiers = rest || s.rest
        modifiers = parse_type(type_and_modifiers, output)

        unless modifiers.blank?
          case output.kind
          when :add_column
            parse_type_modifiers_array(modifiers, output)
          when :association
          else
            raise ParseError, "don't know what to do with `#{modifiers}` for `#{output.kind}` in #{input.inspect}"
          end

        end
      end

      def parse_op_and_name(s, output)
        output.kind = scan_op(s)
        scan_namespace_and_name(s, output)
      end

      def parse_type(type_and_modifiers, output)
        puts "parse_type type_and_modifiers: #{type_and_modifiers.inspect}"
        case type_and_modifiers
        when Empty
          output.type = case output.kind
          when :add_column
            :string
          end
          nil
        when String
          parts = type_and_modifiers.split(":")
          output.type = normalize_type(parts.shift.to_sym)

          if output.kind == :rename_column
            if output.new_name.blank?
              output.new_name = parts.shift
            elsif type_and_modifiers&.length
              raise ParseError, "unknown modifier `#{s.rest}` for rename in `#{type_and_modifiers.inspect}`"
            end
          end
          parts
        else
          raise ParseError, "unexpected type_and_modifiers: #{type_and_modifiers.inspect}"
        end
      end

      def scan_op(s)
        case s.scan(/[+>~]?/)
        when "+"
          :association
        when "~"
          :remove_column
        when ">"
          :rename_column
        else
          :add_column
        end
      end

      def scan_namespace_and_name(s, output)
        puts "scan_namespace_and_name s: #{s.inspect} output: #{output.inspect}"
        s.scan(
          %r{
            (?<namespace>\w+(?=/))?
            /?
            (?<name>\w+)
            (?:>(?<new_name>\w+))?
            :?
          }x
        )
        puts "s: #{s.inspect}"
        output.namespace = s[:namespace]
        if output.namespace && output.kind != :association
          raise ParseError, "can't give column a namespace `#{output.namespace}` in `#{input.inspect}`"
        end
        output.name = s[:name]
        if s[:new_name]
          case output.kind
          when :add_column
            output.kind = :rename_column
          when :association
            output.kind = :rename_association
          when :remove_column
            raise ParseError, "specified both remove_column and rename_column in `#{input.inspect}`"
          end
          output.new_name = s[:new_name]
        end
      end

      def parse_type_modifiers_array(modifiers, output)
        while modifiers && modifiers.length > 0
          modifier = modifiers.shift
          case normalize_type_modifier(modifier, output)
          when :required
            output.required = true
          when :default_value
            raise ParseError, "default value specified but none given in `#{input.inspect}`"
            output.default_value = modifiers.shift
          when :poly
            if in_match = modifiers.first.match(/^in\[(?<poly_in>\w+\])/)
              output.polymorphic_restriction = m[:poly_in].split(/ *, */).map(&:strip)
              modifiers.shift
            end
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
        normalize_type(s[:type])
      end

      def normalize_type(type)
        type = type.to_sym
        return type if Skellie.model_attribute_type_aliases.key?(type)
        type_alias = Skellie.model_attribute_type_aliases.detect { |column_type, aliases|
          aliases&.include?(type)
        }
        raise UnknownType, "unknown type #{type} in `#{input}`" if type_alias.nil?

        type_alias.first.to_sym
      end

      # def validate_modifier_keys(modifier)
      #   valid_keys = VALID_MODIFIER_KEYS
      #     .merge(Skellie.model_attribute_type_aliases)
      #     .merge(Skellie.model_attribute_modifier_aliases)

      #   unknown = modifier.keys - valid_keys
      #   if unknown.length > 1
      #     raise ParseError,
      #       "unknown #{"key".pluralize(unknown.length)}  `#{unknown.inspect}` in #{modifier.inspect}"
      #   end
      # end

      def normalize_type_modifier(modifier, output)
        modifier = modifier.to_sym
        return modifier if Skellie.model_type_modifier_aliases.key?(modifier)
        modifier_alias = Skellie.model_type_modifier_aliases.detect { |column_type, aliases|
          aliases&.include?(modifier)
        }
        raise ParseError, "unknown modifier #{modifier} in `#{input}`" if modifier_alias.nil?

        modifier_alias.first.to_sym
      end
    end
  end
end
