module OffenseToCorrector
  # The annoying thing is that `RuboCop::AST::Node` 's children / descendant
  # methods don't capture all the relevant data, so we have to cheat a bit
  # by wrapping atoms (String, Symbol, Int, etc) in a class to get around that.
  class AtomNode
    attr_reader :source, :range, :parent

    def initialize(source:, range:, parent:)
      @source = source
      @range = range
      @parent = parent
    end

    def to_s
      relevant_children = @parent.children.map do |child|
        next "..." unless child.to_s == self.source.to_s # Wildcard

        case child
        when String then %("#{child}") # Literal string
        when Symbol then ":#{child}"   # Literal symbol
        when nil    then "nil?"
        else child
        end
      end

      # The trick here is that these aren't nodes, but we do care about
      # what the "parent" is that contains it to get something we can
      # work with. All other children are replaced with wildcards.
      "(#{self.parent.type} #{relevant_children.join(' ')})"
    end

    def deconstruct_keys(keys)
      { source:, range:, parent: }
    end
  end
end
