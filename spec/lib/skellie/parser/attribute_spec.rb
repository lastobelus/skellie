require "skellie/parser/attribute"
require "byebug"

PARSED_ATTRIBUTE_DEFAULTS = {
  name: nil,
  kind: nil,
  type: nil,
  namespace: nil,
}

RSpec.describe Skellie::Parser::Attribute do
  shared_examples "parses" do |yaml, expected_attributes|
    it "parses the given yaml to the given structure" do
      parser = described_class.new(YAML.load(yaml))
      attribute = parser.parse
      # ap attribute
      expect(
        attribute
      ).to(
        have_attributes(PARSED_ATTRIBUTE_DEFAULTS.deep_merge(expected_attributes))
      )
    end
  end

  shared_examples "parse error" do |yaml, msg|
    it "raises a parse error" do
      parser = described_class.new(YAML.load(yaml))

      expect {
        parser.parse
      }.to raise_error(Skellie::Parser::Attribute::ParseError, msg)
    end
  end

  def parse!(input, output)
    yaml = YAML.load(input)
    parser = described_class.new(yaml)
    case output
    when Hash
      expect(
        parser.parse
      ).to(
        have_attributes(PARSED_ATTRIBUTE_DEFAULTS.deep_merge(output))
      )
    when Regexp
      expect {
        parser.parse
      }.to raise_error(Skellie::Parser::Attribute::ParseError, output)
    else
      raise "expected output is #{output.class.name} but should be Hash for success or regex for ParseError"
    end
  end

  context "syntax 1 (attribute name AND modifiers are in a single yaml coded string)" do
    it "parses plain attributes" do
      parse! "username", {name: "username",
                          kind: :add_column,
                          type: :string,}
      parse! "bad/username", /can't use a namespace for `add_column`/
    end

    it "parses delete attribute" do
      parse! "~username", {name: "username",
                           kind: :remove_column,}
      parse! "~bad/username", /can't use a namespace for `remove_column`/
    end

    context "types" do
      it "parses attributes with types" do
        parse! "num_stuff:integer", {name: "num_stuff",
                                     kind: :add_column,
                                     type: :integer,}
        parse! "num_stuff:i", {name: "num_stuff",
                               kind: :add_column,
                               type: :integer,}
      end
      it "parses trailing ? as boolean type" do
        parse! "active?", {name: "active",
                           kind: :add_column,
                           type: :boolean,}
      end
    end

    context "attributes with modifiers" do
      it "parses required attributes" do
        parse! "desc:txt:required", {name: "desc",
                                     kind: :add_column,
                                     type: :text,
                                     required: true,}
        parse! "desc:txt:req", {name: "desc",
                                kind: :add_column,
                                type: :text,
                                required: true,}
      end
    end

    context "has_many associations" do
      it "parses plain has_many associations" do
        parse! "+users", {name: "users",
                          kind: :add_association,}
        parse! "+other/users", {name: "users",
                                namespace: "other",
                                kind: :add_association,}
      end
      context "through" do
        it "parses 'through' has_many associations" do
          parse! "+inventors:thru:variants", {name: "inventors",
                                              kind: :add_association,
                                              through: "variants",}
        end

        it "raises when through specified on a non association" do
          parse! "inventors:thru:variants", /can't apply through/
        end

        it "raises when through specified without an entity" do
          parse! "+inventors:thru", /through specified without name/
        end

        it "handles source" do
          parse! "+other_suppliers:thru:other_materials[supplier]",
            {
              name: "other_suppliers",
              kind: :add_association,
              through: "other_materials",
              source: "supplier",
            }
        end

        it "handles source_type" do
          parse! "+crafters:thru:productions[producer,artisan]",
            {
              name: "crafters",
              kind: :add_association,
              through: "productions",
              source: "producer",
              source_type: "artisan",
            }
        end
      end
    end

    context "renaming attributes" do
      it "parses old and new name" do
        parse! "desc>info", {name: "desc",
                             kind: :rename_column,
                             new_name: "info",}
      end
    end

    context "default value" do
      it "parses default value" do
        parse! "category:s:defv:howdy", {name: "category",
                                         kind: :add_column,
                                         type: :string,
                                         default_value: "howdy",}
        parse! "category:defv:howdy", {name: "category",
                                       kind: :add_column,
                                       type: :string,
                                       default_value: "howdy",}
      end
      it "parses default value with required" do
        parse! "category:s:req:defv:howdy", {name: "category",
                                             kind: :add_column,
                                             type: :string,
                                             default_value: "howdy",
                                             required: true,}
      end

      it "parses array and hash defaults for jsonb columns" do
        parse! "profile:jsonb:defv:{}", {name: "profile",
                                         kind: :add_column,
                                         type: :jsonb,
                                         default_value: {},}
        parse! "profile:jsonb:hash", {name: "profile",
                                      kind: :add_column,
                                      type: :jsonb,
                                      default_value: {},}
        parse! "profile:jsonb:defv:[]", {name: "profile",
                                         kind: :add_column,
                                         type: :jsonb,
                                         default_value: [],}
        parse! "profile:jsonb:array", {name: "profile",
                                       kind: :add_column,
                                       type: :jsonb,
                                       default_value: [],}
      end
    end

    context "references (belongs_to associations)" do
      it "parses belongs_to associations and infers class name" do
        parse! "material:ref", {name: "material",
                                kind: :add_column,
                                type: :references,
                                to: "material",}
      end
      it "parses references with specified class name" do
        parse! "main_material:ref:material", {name: "main_material",
                                              kind: :add_column,
                                              type: :references,
                                              to: "material",}
      end
    end
  end

  context "syntax 2 (attribute name is key, modifers are in a coded string" do
    it "parses attributes with types" do
      parse! "num_stuff: integer", {name: "num_stuff",
                                    kind: :add_column,
                                    type: :integer,}
    end

    context "attributes with modifiers" do
      it "parses required attributes" do
        parse! "desc: txt:required", {name: "desc",
                                      kind: :add_column,
                                      type: :text,
                                      required: true,}
        parse! "desc: txt:req", {name: "desc",
                                 kind: :add_column,
                                 type: :text,
                                 required: true,}
      end
    end

    context "associations" do
      it "parses 'through' associations" do
        parse! "+inventors: thru:variants", {name: "inventors",
                                             kind: :add_association,
                                             through: "variants",}
      end

      it "raises when through specified on a non association" do
        parse! "inventors: thru:variants", /can't apply through/
      end

      it "raises when through specified without an entity" do
        parse! "+inventors: thru", /through specified without name/
      end
    end

    context "renaming attributes" do
      it "parses old and new name" do
        parse! "desc>: info", {name: "desc",
                               kind: :rename_column,
                               new_name: "info",}
      end
    end

    context "default value" do
      it "parses default value" do
        parse! "category: s:defv:howdy", {name: "category",
                                          kind: :add_column,
                                          type: :string,
                                          default_value: "howdy",}
        parse! "category: defv:howdy", {name: "category",
                                        kind: :add_column,
                                        type: :string,
                                        default_value: "howdy",}
      end
      it "parses default value with required" do
        parse! "category: s:req:defv:howdy", {name: "category",
                                              kind: :add_column,
                                              type: :string,
                                              default_value: "howdy",
                                              required: true,}
      end

      it "parses array and hash defaults for jsonb columns" do
        parse! "profile: jsonb:defv:{}", {name: "profile",
                                          kind: :add_column,
                                          type: :jsonb,
                                          default_value: {},}
        parse! "profile: jsonb:hash", {name: "profile",
                                       kind: :add_column,
                                       type: :jsonb,
                                       default_value: {},}
        parse! "profile: jsonb:defv:[]", {name: "profile",
                                          kind: :add_column,
                                          type: :jsonb,
                                          default_value: [],}
        parse! "profile: jsonb:array", {name: "profile",
                                        kind: :add_column,
                                        type: :jsonb,
                                        default_value: [],}
      end
    end

    context "references" do
      it "parses references and infers class name" do
        parse! "material: ref", {name: "material",
                                 kind: :add_column,
                                 type: :references,
                                 to: "material",}
      end
      it "parses references and infers class name" do
        parse! "main_material: ref:material", {name: "main_material",
                                               kind: :add_column,
                                               type: :references,
                                               to: "material",}
      end
    end
  end
  # it_behaves_like "parses", yaml, attrs
end
