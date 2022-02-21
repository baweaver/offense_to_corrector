# frozen_string_literal: true

RSpec.describe OffenseToCorrector::AtomNode do
  let(:ast) do
    s(:send, s(:int, 1), :+, s(:int, 1))
  end

  subject do
    described_class.new(
      source: "+",
      range: 2...3,
      parent: ast
    )
  end

  describe ".new" do
    it "creates an instance of an AtomNode" do
      expect(subject).to be_a(described_class)
    end
  end

  describe "#to_s" do
    it "derives a matching pattern from the parent, selecting only it as a child" do
      expect(subject.to_s).to eq("(send ... :+ ...)")
    end
  end

  describe "#deconstruct_keys" do
    it "provides a pattern matching interface" do
      value = case subject
      in source: "+" then true
      else false
      end

      expect(value).to eq(true)
    end
  end
end
