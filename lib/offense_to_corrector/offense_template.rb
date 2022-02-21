module OffenseToCorrector
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
end
