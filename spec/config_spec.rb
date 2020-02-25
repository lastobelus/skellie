context "configure" do
  context "with a hash" do
    context "that is empty" do
      it "returns the defaults" do
        expect(Skellie.configure({})).to be_a Hash
      end
    end
  end

  context "with hash" do
  end

  context "with a file" do
  end
end
