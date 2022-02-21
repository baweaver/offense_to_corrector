module OffenseToCorrector
  class Offense
    # How many underline carots (^), and potentially an error after
    OFFENSE_MATCH = /^ *?(?<underline>\^+) *?(?<error>.*)?$/

    attr_reader :error, :range, :source

    def initialize(error:, range:, source:)
      @error = error
      @range = range
      @source = source
    end

    def deconstruct_keys(keys)
      { error:, range:, source: }
    end

    # See if there's an underline, if so get how long it is and
    # the error message after it
    #
    def self.parse(line:, previous_line:)
      match_data = OFFENSE_MATCH.match(line) or return nil
      underline  = match_data[:underline]
      error      = match_data[:error].lstrip

      underline_start = line.index(underline)
      underline_end   = underline_start + underline.size
      range           = underline_start...underline_end

      source = previous_line.slice(range).chomp

      new(error:, range:, source:)
    end
  end
end
