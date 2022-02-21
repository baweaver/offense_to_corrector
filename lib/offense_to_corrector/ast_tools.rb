module OffenseToCorrector
  module AstTools
    def atom?(value)
      !value.is_a?(RuboCop::AST::Node)
    end

    # I may have to work on getting this one later to try and
    # narrow the band of `AtomNode`
    # def childless?(node)
    #   false # TODO
    # end

    def string_intersection(a, b)
      # Smaller string inside larger string
      target, search_string = a.size < b.size ? [a, b] : [b, a]

      last_char_index = target.size.downto(1).find do |i|
        search_string.include?(target[0..i])
      end or return ""

      target[0..last_char_index]
    end

    # How much do two ranges overlap? Used to see how well a node
    # matches with the associated underline
    def range_overlap_count(a, b)
      return [a.end, b.end].min - b.begin if a.cover?(b.begin)
      return [a.end, b.end].min - a.begin if b.cover?(a.begin)

      0
    end

    # See if a range overlaps another one, bidirectional
    def range_overlap?(a, b)
      a.cover?(b.begin) || b.cover?(a.begin)
    end

    # To get an AST we need the processed source of a string
    def processed_source_from(string)
      RuboCop::ProcessedSource.new(string, RUBY_VERSION.to_f)
    end

    # So why bother with the above then? If we end up into correctors
    # and tree-rewrites we need that original processed source to be
    # the basis of the AST, otherwise we get object ID mismatches.
    def ast_from(value)
      case value
      when RuboCop::ProcessedSource
        value.ast
      else
        processed_source_from(value).ast
      end
    end

    # Not needed quite yet, but could very potentially be used to verify
    # how accurate generated cops are.
    def get_corrector(value)
      RuboCop::Cop::Corrector.new(value.buffer)
    end

    # Descendants leaves out a _lot_ of detail potentially. There has to
    # be a better way to deal with this, but not thinking of one right now.
    def get_children(source_node)
      recurse = -> parent do
        collected_children = []
        parent.children.each do |child|
          next if child.nil?

          # If it's a regular parent carry on as you were
          unless atom?(child) # || childless?(child)
            collected_children.concat([child, *recurse[child]])
            next
          end

          # Otherwise we want to find where that parent is in the source code,
          # and the range it exists in, to create an `AtomNode`
          source = child.to_s

          parent_begin = parent.location.expression.to_range.begin
          range_begin  = source_node.source.index(source, parent_begin)
          range_end    = range_begin + source.size
          range        = range_begin..range_end

          collected_children << AtomNode.new(parent:, source:, range:)
        end

        collected_children
      end

      [source_node, *recurse[source_node]]
    end
  end
end
