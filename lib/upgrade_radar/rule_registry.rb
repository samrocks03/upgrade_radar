# frozen_string_literal: true

module UpgradeRadar
  class RuleRegistry
    attr_reader :rules

    def initialize
      @rules = []
    end

    def load_builtin_rules
      Dir[File.join(UpgradeRadar::RULES_PATH, "**", "*.yml")].sort.each do |path|
        load_file(path)
      end
      self
    end

    def load_custom_rules(path)
      Dir[File.join(path, "**", "*.yml")].sort.each do |file_path|
        load_file(file_path)
      end
      self
    end

    def rules_for(from_range, to_range)
      @rules.select do |rule|
        rule.framework == from_range.framework &&
          rule.applies?(from_range.version, to_range.version)
      end
    end

    private

    def load_file(path)
      entries = YAML.safe_load_file(path, permitted_classes: []) || []
      entries.each do |attrs|
        rule = Rule.new(attrs)
        raise "Duplicate rule id: #{rule.id}" if @rules.any? { |r| r.id == rule.id }
        @rules << rule
      end
    end
  end
end
