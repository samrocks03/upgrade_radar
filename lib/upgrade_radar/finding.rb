# frozen_string_literal: true

module UpgradeRadar
  class Finding
    attr_reader :rule, :filepath, :line, :column, :source, :severity

    def initialize(rule:, filepath:, line:, column:, source:, severity:)
      @rule = rule
      @filepath = filepath
      @line = line
      @column = column
      @source = source.to_s.strip
      @severity = severity
    end

    def id
      rule.id
    end

    def message
      rule.message
    end

    def effort_minutes
      rule.effort_minutes
    end

    def to_h
      {
        id: rule.id,
        severity: severity,
        file: filepath,
        line: line,
        column: column,
        source: source,
        message: rule.message,
        replacement: rule.replacement,
        docs: rule.docs,
        effort_minutes: effort_minutes
      }
    end
  end
end
