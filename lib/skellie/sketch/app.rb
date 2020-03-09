module Skellie
  module Sketch
    class App
      attr_accessor :h, :path

      def initialize(file:)
        @path = file
        read_file
      end

      def read_file
        @h = YAML.load(IO.read(path)).deep_symbolize_keys
      end

      def models
        @h[:models].map { |model_sketch|
          Model.new(model_sketch)
        }
      end
    end
  end
end
