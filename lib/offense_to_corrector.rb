# frozen_string_literal: true

require_relative "offense_to_corrector/version"

require "rubocop"
require "erb"

require "offense_to_corrector/atom_node"
require "offense_to_corrector/ast_tools"
require "offense_to_corrector/offense"
require "offense_to_corrector/offense_parser"
require "offense_to_corrector/offense_template"

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
end
