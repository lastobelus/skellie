require "attr_extras"

module Skellie
  module Sketch
    class Attribute
      aattr_initialize [:name, :namespace, :kind, :type]
    end
  end
end
