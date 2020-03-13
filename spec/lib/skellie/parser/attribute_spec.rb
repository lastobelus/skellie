require "skellie/parser/attribute"
require "skellie/parser/parse_error"
require "byebug"

PARSED_ATTRIBUTE_DEFAULTS = {
  name: nil,
  kind: nil,
  type: nil,
  namespace: nil,
}

def parse!(input, output)
  yaml = YAML.load(input)
  parser = Skellie::Parser::Attribute.new(yaml)
  case output
  when Hash
    it "parses `#{input}` to #{inspect_hash(output)}" do
      expect(
        parser.parse
      ).to(
        have_attributes(PARSED_ATTRIBUTE_DEFAULTS.deep_merge(output))
      )
    end
  when Regexp
    it "raises ParseError for `#{yaml}`" do
      expect {
        parser.parse
      }.to raise_error(Skellie::Parser::ParseError, output)
    end
  else
    raise "expected output is #{output.class.name} but should be Hash for success or regex for ParseError"
  end
end

def inspect_hash(hash)
  hash.map { |key, value| "#{key}: #{value}" }.join(", ")
end

RSpec.describe Skellie::Parser::Attribute do
  context "syntax 1 (attribute name AND modifiers are in a single yaml coded string)" do
    context "simple attributes" do
      parse! "username", {name: "username",
                          kind: :add_column,
                          type: :string,}
      parse! "bad/username", /can't use a namespace for `add_column`/
    end

    context "deleting attributes" do
      parse! "~username", {name: "username",
                           kind: :remove_column,}
      parse! "~bad/username", /can't use a namespace for `remove_column`/
    end

    context "attributes with types" do
      parse! "num_stuff:integer", {name: "num_stuff",
                                   kind: :add_column,
                                   type: :integer,}
      parse! "num_stuff:i", {name: "num_stuff",
                             kind: :add_column,
                             type: :integer,}
      parse! "active?", {name: "active",
                         kind: :add_column,
                         type: :boolean,}
    end

    context "attributes with modifiers" do
      parse! "desc:txt:required", {name: "desc",
                                   kind: :add_column,
                                   type: :text,
                                   required: true,}
      parse! "desc:txt:req", {name: "desc",
                              kind: :add_column,
                              type: :text,
                              required: true,}
    end

    context "has_many associations" do
      parse! "+users", {name: "users",
                        kind: :add_association,}
      parse! "+other/users", {name: "users",
                              namespace: "other",
                              kind: :add_association,}
      context "has_many through" do
        parse! "+inventors:thru:variants", {name: "inventors",
                                            kind: :add_association,
                                            through: "variants",}
        parse! "inventors:thru:variants", /can't apply through/
        parse! "+inventors:thru", /through specified without name/
        parse! "+other_suppliers:thru:other_materials[supplier]",
          {
            name: "other_suppliers",
            kind: :add_association,
            through: "other_materials",
            source: "supplier",
          }
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

    context "renaming attributes" do
      parse! "desc>info", {name: "desc",
                           kind: :rename_column,
                           new_name: "info",}
    end

    context "default value" do
      parse! "category:s:defv:howdy", {name: "category",
                                       kind: :add_column,
                                       type: :string,
                                       default_value: "howdy",}
      parse! "category:defv:howdy", {name: "category",
                                     kind: :add_column,
                                     type: :string,
                                     default_value: "howdy",}
      parse! "category:s:req:defv:howdy", {name: "category",
                                           kind: :add_column,
                                           type: :string,
                                           default_value: "howdy",
                                           required: true,}

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

    context "references (belongs_to associations)" do
      parse! "material:ref", {name: "material",
                              kind: :add_column,
                              type: :references,
                              to: "material",}
      parse! "main_material:ref:material", {name: "main_material",
                                            kind: :add_column,
                                            type: :references,
                                            to: "material",}
    end
  end

  context "syntax 2 (attribute name is key, modifers are in a coded string" do
    context "attributes with types" do
      parse! "num_stuff: integer", {name: "num_stuff",
                                    kind: :add_column,
                                    type: :integer,}
    end

    context "attributes with modifiers" do
      parse! "desc: txt:required", {name: "desc",
                                    kind: :add_column,
                                    type: :text,
                                    required: true,}
      parse! "desc: txt:req", {name: "desc",
                               kind: :add_column,
                               type: :text,
                               required: true,}
    end

    context "associations" do
      context "has_many through" do
        parse! "+inventors: thru:variants", {name: "inventors",
                                             kind: :add_association,
                                             through: "variants",}

        parse! "inventors: thru:variants", /can't apply through/

        parse! "+inventors: thru", /through specified without name/
      end
    end

    context "renaming attributes" do
      parse! "desc>: info", {name: "desc",
                             kind: :rename_column,
                             new_name: "info",}
    end

    context "default value" do
      parse! "category: s:defv:howdy", {name: "category",
                                        kind: :add_column,
                                        type: :string,
                                        default_value: "howdy",}
      parse! "category: defv:howdy", {name: "category",
                                      kind: :add_column,
                                      type: :string,
                                      default_value: "howdy",}
      parse! "category: s:req:defv:howdy", {name: "category",
                                            kind: :add_column,
                                            type: :string,
                                            default_value: "howdy",
                                            required: true,}
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

    context "references" do
      parse! "material: ref", {name: "material",
                               kind: :add_column,
                               type: :references,
                               to: "material",}
      parse! "main_material: ref:material", {name: "main_material",
                                             kind: :add_column,
                                             type: :references,
                                             to: "material",}
    end
  end
  # it_behaves_like "parses", yaml, attrs
end
