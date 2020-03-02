require "attr_extras"

module Skellie
  module Sketch
    class Attribute
      aattr_initialize [:name, :namespace, :kind, :type, :required, :new_name, :polymorphic_restriction]
      attr_query :required?
    end
  end
end
