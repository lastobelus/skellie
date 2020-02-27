require "skellie/sketch/attribute"

RSpec.describe Skellie::Sketch::Attribute do
  subject { described_class.new(str) }

  context "plain string attribute" do
    let(:str) { "username" }
    it {
      is_expected.to have_attributes(
        name: "username",
        namespace: nil,
        kind: :add_column
      )
    }
    context "with namespace" do
      let(:str) { "bad/username" }
      it {
        expect { subject }.to raise_error(Skellie::Sketch::Attribute::ParseError, "can't give column a namespace `bad` in `bad/username`")
      }
    end
  end

  context "delete column" do
    let(:str) { "~username" }
    it {
      is_expected.to have_attributes(
        name: "username",
        namespace: nil,
        kind: :remove_column
      )
    }
    context "with namespace" do
      let(:str) { "~bad/username" }
      it {
        expect { subject }.to raise_error(Skellie::Sketch::Attribute::ParseError, "can't give column a namespace `bad` in `~bad/username`")
      }
    end
  end

  context "attributes with types" do
    context "written out in full", focus: true do
      let(:str) { "num_stuff:integer" }
      it {
        is_expected.to have_attributes(
          name: "num_stuff",
          namespace: nil,
          kind: :add_column,
          type: :integer
        )
      }
    end

    context "using an alias" do
    end
  end

  context "associations" do
    context "has_many" do
      let(:str) { "+users" }
      it {
        is_expected.to have_attributes(
          name: "users",
          namespace: nil,
          kind: :association
        )
      }
      context "with namespace" do
        let(:str) { "+other/users" }
        it {
          is_expected.to have_attributes(
            name: "users",
            namespace: "other",
            kind: :association
          )
        }
      end
    end
  end
end
