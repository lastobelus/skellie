require "skellie/parser/attribute"
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

  context "syntax 1 (attribute name AND modifiers are in a single yaml coded string)" do
    it_behaves_like "parses", "username", {name: "username",
                                           kind: :add_column,
                                           type: :string,}
    it_behaves_like "parse error", "bad/username", /can't give column a namespace/

    it_behaves_like "parses", "~username", {name: "username",
                                            kind: :remove_column,}
    it_behaves_like "parse error", "bad/username", /can't give column a namespace/

    it_behaves_like "parses", "+users", {name: "users",
                                         kind: :association,}
    it_behaves_like "parses", "+other/users", {name: "users",
                                               namespace: "other",
                                               kind: :association,}
    it_behaves_like "parses", "num_stuff:integer", {name: "num_stuff",
                                                    kind: :add_column,
                                                    type: :integer,}
    it_behaves_like "parses", "num_stuff:i", {name: "num_stuff",
                                              kind: :add_column,
                                              type: :integer,}
  end

  context "syntax 2 (attribute name is key, modifers are in a coded string" do
    it_behaves_like "parses", "num_stuff: integer", {name: "num_stuff",
                                                     kind: :add_column,
                                                     type: :integer,}
  end
  # it_behaves_like "parses", yaml, attrs
end
