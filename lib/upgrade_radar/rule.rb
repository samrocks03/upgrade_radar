# frozen_string_literal: true

module UpgradeRadar
  class Rule
    attr_reader :id, :framework, :introduced_in, :breaking_in,
                :pattern, :message, :replacement, :docs, :effort_minutes, :confidence

    def initialize(attrs)
      @id = attrs.fetch("id")
      @framework = attrs.fetch("framework")
      @introduced_in = Gem::Version.new(attrs.fetch("introduced_in").to_s)
      @breaking_in = Gem::Version.new(attrs.fetch("breaking_in").to_s)
      @pattern = attrs.fetch("pattern")
      @message = attrs.fetch("message").strip
      @replacement = attrs["replacement"]&.strip
      @docs = attrs["docs"]
      @effort_minutes = attrs.fetch("effort_minutes", 10)
      @confidence = attrs.fetch("confidence", "high")
    end

    def applies?(from_version, to_version)
      breaking_in >= from_version && introduced_in <= to_version
    end

    def low_confidence?
      confidence == "low"
    end

    # Low-confidence rules can't tell statically whether the receiver is
    # affected, so they never fail a scan on their own.
    def severity_for(to_version)
      return :warning if low_confidence?

      to_version >= breaking_in ? :breaking : :warning
    end

    def node_types
      case pattern["type"]
      when "method_call", "string_mutation"
        [:call_node]
      when "constant_reference"
        [:constant_read_node, :constant_path_node]
      when "block_parameter"
        [:call_node]
      when "gemfile_dependency"
        [:special]
      else
        []
      end
    end
  end
end
