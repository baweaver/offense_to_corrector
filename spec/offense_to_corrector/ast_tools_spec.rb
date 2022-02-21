# frozen_string_literal: true

class Tools
  extend OffenseToCorrector::AstTools
end

RSpec.describe OffenseToCorrector::AstTools do
  describe "#atom?" do
    it "is not an atom if it's an AST Node" do
      expect(Tools.atom?(RuboCop::AST::Node.new(:send))).to eq(false)
    end

    it "is an atom otherwise" do
      expect(Tools.atom?(1)).to eq(true)
    end
  end

  describe "#string_intersection" do
    it "finds the intersection when the first is shorter than the second" do
      expect(Tools.string_intersection("abc", "abcdef")).to eq("abc")
    end

    it "finds the intersection when the second is shorter than the first" do
      expect(Tools.string_intersection("abcdef", "abc")).to eq("abc")
    end

    it "finds partial intersections when the strings don't completely overlap" do
      expect(Tools.string_intersection("abcfed", "abcdef")).to eq("abc")
    end
  end

  describe "#range_overlap_count" do
    it "finds the overlap of two ranges" do
      expect(Tools.range_overlap_count(0..5, 3..7)).to eq(2)
    end

    it "is not left-biased" do
      expect(Tools.range_overlap_count(3..7, 0..5)).to eq(2)
    end

    it "returns 0 if there are no overlaps" do
      expect(Tools.range_overlap_count(0..5, 8..15)).to eq(0)
    end
  end

  describe "#range_overlap?" do
    it "finds if two ranges overlap" do
      expect(Tools.range_overlap?(0..5, 3..7)).to eq(true)
    end

    it "is not left-biased" do
      expect(Tools.range_overlap?(3..7, 0..5)).to eq(true)
    end

    it "returns false if there are no overlaps" do
      expect(Tools.range_overlap?(0..5, 8..15)).to eq(false)
    end
  end

  describe "#processed_source_from" do
    it "turns a String into ProcessedSource" do
      expect(Tools.processed_source_from("1 + 1")).to be_a(RuboCop::ProcessedSource)
    end
  end

  describe "#ast_from" do
    it "turns a String into an AST Node" do
      expect(Tools.ast_from("1 + 1")).to be_a(RuboCop::AST::Node)
    end
  end

  describe "#get_corrector" do
    it "turns a ProcessedSource into Corrector" do
      expect(
        Tools.get_corrector(Tools.processed_source_from("1 + 1"))
      ).to be_a(RuboCop::Cop::Corrector)
    end
  end

  describe "#get_children" do
    it "gets all children" do
      # Example output from: 1 + 1
      #
      # [
      #   1        2       3    4  5       6 # Counts
      #   s(:send, s(:int, 1), :+, s(:int, 1)),
      #   s(:int, 1),
      #   AtomNode[source: "1", range: 0..1, parent: s(:int, 1)],
      #   AtomNode[source: "+", range: 2..3, parent: s(:send, s(:int, 1), :+, s(:int, 1))],
      #   s(:int, 1),
      #   AtomNode[source: "1", range: 4..5, parent: s(:int, 1)]
      # ]

      expect(Tools.get_children(
        Tools.ast_from("1 + 1")
      ).size).to eq(6)
    end
  end
end
