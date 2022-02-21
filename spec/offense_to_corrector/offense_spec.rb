# frozen_string_literal: true

RSpec.describe OffenseToCorrector::Offense do
  let(:code) do
    <<~RUBY
        update_attributes_book.update_attributes(author: "Alice")
                               ^^^^^^^^^^^^^^^^^ Use `update` instead.
        1 + 1
    RUBY
  end

  let(:code_lines) { code.lines }

  subject do
    described_class.new(
      error: "Use `update` instead.",
      range: 23...40,
      source: "update_attributes"
    )
  end

  describe ".new" do
    it "creates an instance of an Offense" do
      expect(subject).to be_a(described_class)
    end
  end

  describe ".parse" do
    it "will find an offense line when one exists" do
      offense = described_class.parse(
        line: code_lines[1],
        previous_line: code_lines[0]
      )

      expect(offense).to be_a(described_class)
      expect(offense).to have_attributes(
        error: "Use `update` instead.",
        range: 23...40,
        source: "update_attributes"
      )
    end

    it "will not find an offense unless it matches the offense format" do
      offense = described_class.parse(
        line: code_lines[2],
        previous_line: code_lines[1]
      )

      expect(offense).to be(nil)
    end
  end

  describe "#deconstruct_keys" do
    it "provides a pattern matching interface" do
      value = case subject
      in error: /update/, source: /update/ then true
      else false
      end

      expect(value).to eq(true)
    end
  end
end
