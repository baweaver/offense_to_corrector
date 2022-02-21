module OffenseToCorrector
  class OffenseParser
    include AstTools

    attr_reader :ast, :source, :offense, :ast_nodes

    def initialize(string)
      @ast_lines,  @offense = parse_string(string)
      @source = processed_source_from(@ast_lines.join("\n"))
      @ast = ast_from(@source)
      @ast_nodes = get_children(@ast)
      @template = OffenseTemplate.new
    end

    # Render that into the cop skeleton. Perhaps having too much
    # fun here with rightward assignment.
    def render
      call => {
        offense: { error: },
        node_offense_info: { offending_node:, offending_node_matcher: }
      }

      @template.render(
        class_name: "TODO",
        match_pattern: offending_node_matcher,
        error_message: error,
        node_type: offending_node.type,
        cop_type: "Lint",
        node_location: "selector",
        offense_severity: "warning"
      )
    end

    # Quick info on what all is being worked on and what info we got
    def deconstruct_keys(keys)
      { ast:, source:, offense:, node_offense_info: }
    end

    def node_offense_info
      return @node_offense_info if defined?(@node_offense_info)

      # Find the node, or atom, with the most overlap with the offense
      # range defined by that underline. That's defined as a pair of
      # the length of the intersection as well as what percentage that
      # intersection makes of the full node source.
      offending_node = @ast_nodes.max_by do |node|
        intersection = string_intersection(node.source, @offense.source)
        [intersection.size, intersection.size.fdiv(node.source.size)]
      end

      @node_offense_info ||= {
        offending_node:,
        offending_node_matcher: offending_node.to_s
      }
    end

    private def node_range(node)
      if node.is_a?(AtomNode)
        node.range
      else
        node.location.expression.to_range
      end
    end

    # Figure which part of the passed in code string is AST vs offense
    private def parse_string(string)
      ast_lines = []
      offense = nil
      lines = string.lines

      lines.each_with_index do |line, i|
        # No sense of a meta-line being above every other line
        meta_info = i > 0 && Offense.parse(line:, previous_line: lines[i - 1])

        if meta_info
          raise "Cannot have multiple offenses" unless offense.nil?
          offense = meta_info
        else
          ast_lines << line
        end
      end

      [ast_lines, offense]
    end
  end
end
