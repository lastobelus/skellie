require "skellie/sketch/attribute"
require "active_support/core_ext/string/inflections"

module Skellie
  module Parser
    class Attribute
      class Empty
        def self.===(object)
          !object || object.blank? || object.empty?
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
        puts "parse_from_string_parts op_and_name: #{op_and_name.inspect} rest: #{rest.inspect}"
        s = StringScanner.new(op_and_name)
        ops, output.name, output.namespace = parse_ops_and_name(s)
        output.kind = normalize_ops(ops)
        s = s.eos? ? StringScanner.new(rest || "") : s

        if output.rename?
          output.new_namespace, output.new_name = scan_namespace_and_name(s)
        end

        puts "output.namespace: #{output.namespace.inspect}"
        puts "output.kind: #{output.kind.inspect}"
        if output.namespace && !output.namespace_allowed?
          raise ParseError, "can't use a namespace for `#{output.kind}` in `#{input.inspect}`"
        end

        type_and_modifiers = s.rest
        modifiers = parse_type(type_and_modifiers, output)

        unless modifiers.blank?
          case output.kind
          when :add_column
            parse_type_modifiers_array(modifiers, output)
          when :add_association
          else
            raise ParseError, "don't know what to do with `#{modifiers}` for `#{output.kind}` in #{input.inspect}"
          end

        end
      end

      def parse_ops_and_name(s)
        ops = scan_ops(s)
        namespace, name = scan_namespace_and_name(s)
        ops += scan_ops(s)
        [ops, name, namespace]
      end

      def normalize_ops(ops)
        puts "ops: #{ops.inspect}"
        case ops.sort.uniq
        when %w[+]
          :add_association
        when %w[~]
          :remove_column
        when %w[+~]
          :remove_association
        when %w[>]
          :rename_column
        when %w[+>]
          :rename_association
        when Empty
          :add_column
        end
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

      def scan_ops(s)
        ops = []
        until (op = s.scan(/[+>~]?/)).blank?
          ops << op
        end
        ops
      end

      def scan_namespace_and_name(s)
        puts "scan_namespace_and_name s: #{s.inspect}"
        s.scan(
          %r{
            (?<namespace>\w+(?=/))?
            /?
            (?<name>\w+)
            :?
          }x
        )
        ap s
        [s[:namespace], s[:name]]
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
