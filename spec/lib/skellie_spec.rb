RSpec.describe "Skellie.configure" do
  shared_examples "default config" do
    it "has default model type_aliases for integer" do
      expect(config).to include(
        models: hash_including(
          type_aliases: hash_including(
            integer: %i[i int]
          )
        )
      )
    end
  end

  context "with a hash" do
    context "that is empty" do
      subject(:config) { Skellie.configure({}) }

      include_examples "default config"
      it "returns the defaults" do
        expect(config).to be_a Hash
      end
    end

    context "with nested values" do
      subject(:config) { Skellie.configure(models: {type_aliases: {decimal: %i[deci]}}) }

      include_examples "default config"

      it "deep merges with the defaults" do
        expect(config).to include(
          models: hash_including(
            type_aliases: hash_including(
              decimal: %i[deci]
            )
          )
        )
      end
    end

    context "with duplicate types" do
      subject(:config) { Skellie.configure(models: {type_aliases: {decimal: %i[deci int d]}}) }

      it "raises an error" do
        expect { subject }.to raise_error(Skellie::Error, "duplicate type_aliases: int, d")
      end
    end
  end

  context "with a file" do
    subject(:config) { Skellie.configure(config_fixture("add_model_type_alias_for_float")) }

    include_examples "default config"

    it "deep merges with the defaults" do
      expect(config).to include(
        models: hash_including(
          type_aliases: hash_including(
            float: %i[flo]
          )
        )
      )
    end
  end
end
