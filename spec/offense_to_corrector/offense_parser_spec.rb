# frozen_string_literal: true

RSpec.describe OffenseToCorrector::OffenseParser do
  let(:code) do
    <<~RUBY
        update_attributes_book.update_attributes(author: "Alice")
                               ^^^^^^^^^^^^^^^^^ Use `update` instead.
        1 + 1
    RUBY
  end

  let(:code_lines) { code.lines }

  subject do
    described_class.new(code)
  end

  describe ".new" do
    it "creates an instance of an Offense" do
      expect(subject).to be_a(described_class)
    end
  end

  describe "#node_offense_info" do
    it "captures offending node information" do
      subject.node_offense_info => { offending_node_matcher: }
      expect(offending_node_matcher).to eq("(send ... :update_attributes ...)")
    end

    it "can differentiate between parent nodes and child node overlaps" do
      subject = described_class.new <<~RUBY
        @template = OffenseTemplate.new
                                   ^^^^
      RUBY

      subject.node_offense_info => { offending_node_matcher: }
      expect(offending_node_matcher).to eq <<~AST.chomp
        (send
          (const nil :OffenseTemplate) :new)
      AST
    end

    it "will employ an atom match if set to an atom" do
      subject = described_class.new <<~RUBY
        @template = OffenseTemplate.new
                                    ^^^
      RUBY

      subject.node_offense_info => { offending_node_matcher: }
      expect(offending_node_matcher).to eq <<~AST.chomp
        (send ... :new)
      AST
    end

    it "will match a whole node" do
      subject = described_class.new <<~RUBY
        @template = OffenseTemplate.new
                    ^^^^^^^^^^^^^^^
      RUBY

      subject.node_offense_info => { offending_node_matcher: }
      expect(offending_node_matcher).to eq <<~AST.chomp
        (const nil :OffenseTemplate)
      AST
    end

    it "match an instance variable assignment due to nearest overlapping node" do
      subject = described_class.new <<~RUBY
        @template = OffenseTemplate.new
        ^^^^^^^^^
      RUBY

      subject.node_offense_info => { offending_node_matcher: }
      expect(offending_node_matcher).to eq <<~AST.chomp
        (ivasgn :@template ...)
      AST
    end
  end

  describe "#decosntruct_keys" do
    it "provides a pattern matching interface" do
      subject => { node_offense_info: { offending_node_matcher: } }

      expect(offending_node_matcher).to eq("(send ... :update_attributes ...)")
    end
  end
end
