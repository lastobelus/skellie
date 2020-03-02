require "attr_extras"

module Skellie
  module Sketch
    class Attribute
      aattr_initialize [:name, :namespace, :kind, :type, :required, :new_name, :new_namespace, :polymorphic_restriction]
      attr_query :required?

      def rename?
        %i[rename_column rename_association].include? kind
      end

      def namespace_allowed?
        %i[add_association remove_association rename_association].include? kind
      end
    end
  end
end
