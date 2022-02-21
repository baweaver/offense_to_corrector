# frozen_string_literal: true

require_relative "offense_to_corrector/version"

require "rubocop"
require "erb"

module OffenseToCorrector
  module_function def load_template(name)
    File.join(File.dirname(__FILE__), "offense_to_corrector/templates", name)
  end

  module_function def node_offense_data(code)
    OffenseParser.new(code).node_offense_info
  end

  module_function def offense_to_cop(code)
    OffenseParser.new(code).render
  end

  # The annoying thing is that `RuboCop::AST::Node` 's children / descendant
  # methods don't capture all the relevant data, so we have to cheat a bit
  # by wrapping atoms (String, Symbol, Int, etc) in a class to get around that.
  AtomNode = Struct.new(:source, :range, :parent, keyword_init: true) do
    def type
      self.parent.type
    end

    def to_s
      relevant_children = self.parent.children.map do |c|
        next "..." unless c.to_s == self.source.to_s # Wildcard

        case c
        when String then %("#{c}") # Literal string
        when Symbol then ":#{c}"   # Literal symbol
        else c
        end
      end

      # The trick here is that these aren't nodes, but we do care about
      # what the "parent" is that contains it to get something we can
      # work with. All other children are replaced with wildcards.
      "(#{self.parent.type} #{relevant_children.join(' ')})"
    end
  end

  module AstTools
    def atom?(value)
      !value.is_a?(RuboCop::AST::Node)
    end

    # I may have to work on getting this one later to try and
    # narrow the band of `AtomNode`
    # def childless?(node)
    #   false # TODO
    # end

    # How much do two ranges overlap? Used to see how well a node
    # matches with the associated underline
    def range_overlap_count(a, b)
      return (b.begin...[a.end, b.end].min).size if a.cover?(b.begin)
      return (a.begin...[a.end, b.end].min).size if b.cover?(a.begin)

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
      recurse = -> node do
        collected_children = []
        node.children.each do |child|
          next if child.nil?

          # If it's a regular node carry on as you were
          unless atom?(child) # || childless?(child)
            collected_children.concat([child, *recurse[child]])
            next
          end

          # Otherwise we want to find where that node is in the source code,
          # and the range it exists in, to create an `AtomNode`
          child_string = child.to_s
          range_begin = source_node.source.index(/\b#{child_string}\b/)
          range_end   = range_begin + child_string.size

          collected_children << AtomNode.new(
            parent: node,
            source: child_string,
            range: range_begin..range_end
          )
        end

        collected_children
      end

      [source_node, *recurse[source_node]]
    end
  end

  # ERB template for rendering a cop skeleton, may make this more useful
  # later, but mostly quick templating for now.
  class OffenseTemplate
    def initialize(name: "autocorrector_template.erb")
      @template = File.read(OffenseToCorrector.load_template(name))
      @erb = ERB.new(@template)
    end

    def render(
      class_name: "TODO",
      match_pattern:,
      error_message: "",
      node_type:,
      cop_type: "Lint",
      node_location: "selector",
      offense_severity: "warning"
    )
      @erb.result_with_hash(
        class_name:,
        match_pattern:,
        error_message:,
        node_type:,
        cop_type:,
        node_location:,
        offense_severity:
      )
    end
  end

  # Bit more of a structured container for an offense (the underline)
  Offense = Struct.new(:line, :error, :range, keyword_init: true)

  class OffenseParser
    include AstTools

    # How many underline carots (^), and potentially an error after
    OFFENSE_MATCH = /^ *?(?<underline>\^+) *?(?<error>.*)?$/

    attr_reader :ast, :source, :offense

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
    def call
      { ast:, offense:, node_offense_info: }
    end

    def node_offense_info
      return @node_offense_info if defined?(@node_offense_info)

      # Find the node, or atom, with the most overlap with the offense
      # range defined by that underline.
      offending_node = @ast_nodes.max do |node|
        node_range = if node.is_a?(AtomNode)
          node.range
        else
          node.location.expression.to_range
        end

        # Except we're doing it as a percentage, otherwise parent nodes
        # will dominate that count potentially. The closer to 100% overlap
        # the better.
        overlap_count = range_overlap_count(node_range, @offense[:range])
        overlap_count.fdiv(node.source.size)
      end

      @node_offense_info ||= {
        offending_node:,
        offending_node_matcher: offending_node.to_s
      }
    end

    # See if there's an underline, if so get how long it is and
    # the error message after it
    private def offending_meta_from(line)
      match_data = OFFENSE_MATCH.match(line) or return nil
      underline  = match_data[:underline]
      error      = match_data[:error].lstrip

      underline_start = line.index(underline)
      underline_end   = underline_start + underline.size

      { match_data:, error:, range: underline_start..underline_end }
    end

    # Figure which part of the passed in code string is AST vs offense
    private def parse_string(string)
      ast_lines = []
      offense = nil

      string.lines.each_with_index do |line, i|
        meta_info = offending_meta_from(line)

        if meta_info
          raise "Cannot have multiple offenses" unless offense.nil?
          offense = Offense.new(line: i, **meta_info.slice(:error, :range))
        else
          ast_lines << line
        end
      end

      [ast_lines, offense]
    end
  end
end
