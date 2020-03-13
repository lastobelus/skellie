require "attr_extras"

module Skellie
  module Sketch
    # holds the settings for a parsed model attribute. Used by the generator
    # to generate the necessary model, migration, git operations.
    class Attribute
      aattr_initialize [
        :name, :namespace,
        :kind, :type, :required, :optional,
        :new_name, :new_namespace,
        :polymorphic_restriction, :default_value, :to,
        :through, :source, :source_type,
      ]
      attr_query :required?

      def rename?
        %i[rename_column rename_association].include? kind
      end

      def namespace_allowed?
        %i[add_association remove_association rename_association].include? kind
      end

      def accepts_type?
        %i[add_column rename_column].include? kind
      end

      def accepts_default_type?
        %i[add_column].include? kind
      end

      def accepts_through?
        %i[add_association].include? kind
      end

      def reference?
        type == :references
      end

      def default_value=(val)
        @default_value = case val
        when "{}", :hash, "hash"
          {}
        when "[]", :array, "array"
          []
        else
          val
        end
      end

      def set_namespace_and_name(args)
        self.namespace = args.first
        self.name = args.last
      end

      def set_new_namespace_and_name(args)
        self.new_namespace = args.first
        self.new_name = args.last
      end

      def invalid_namespace?
        namespace && !namespace_allowed?
      end
    end
  end
end
