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
      parse! "bad/username", /can't give column a namespace/
    end

    it "parses delete attribute" do
      parse! "~username", {name: "username",
                           kind: :remove_column,}
      parse! "~bad/username", /can't give column a namespace/
    end

    it "parses plain associations" do
      parse! "+users", {name: "users",
                        kind: :association,}
      parse! "+other/users", {name: "users",
                              namespace: "other",
                              kind: :association,}
    end

    it "parses attributes with types" do
      parse! "num_stuff:integer", {name: "num_stuff",
                                   kind: :add_column,
                                   type: :integer,}
      parse! "num_stuff:i", {name: "num_stuff",
                             kind: :add_column,
                             type: :integer,}
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

    context "renaming attributes" do
      it "parses old and new name" do
        parse! "desc>info", {name: "desc",
                             kind: :rename_column,
                             new_name: "info",}
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

    context "renaming attributes" do
      it "parses old and new name" do
        parse! "desc>: info", {name: "desc",
                               kind: :rename_column,
                               new_name: "info",}
      end
    end
  end
  # it_behaves_like "parses", yaml, attrs
end
