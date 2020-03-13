require "skellie/parser/parse_error"

module Skellie
  module Parser
    module ParseErrors
      module Attributes
        # raised when a namespace is set for a plain attribute (column)
        class InvalidNamespaceError < Skellie::Parser::ParseError
          def initialize(input, output)
            super "can't use a namespace for `#{output.kind}` in `#{input.inspect}`"
          end
        end
      end
    end
  end
end
