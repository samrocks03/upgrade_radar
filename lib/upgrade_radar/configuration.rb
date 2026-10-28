# frozen_string_literal: true

module UpgradeRadar
  class Configuration
    attr_reader :scan_path, :exclude_patterns, :custom_rules_path, :severity_threshold

    DEFAULT_CONFIG_FILE = ".upgrade_radar.yml"

    def initialize(options = {})
      @scan_path = File.expand_path(options[:path] || ".")
      @exclude_patterns = options[:exclude] || []
      @custom_rules_path = nil
      @severity_threshold = :all

      load_config_file(options[:config])
    end

    private

    def load_config_file(explicit_path)
      config_path = explicit_path || File.join(@scan_path, DEFAULT_CONFIG_FILE)
      return unless File.exist?(config_path)

      config = YAML.safe_load_file(config_path, permitted_classes: []) || {}

      @exclude_patterns += Array(config["exclude"])
      @custom_rules_path = config["custom_rules_path"]
      @severity_threshold = config["severity_threshold"]&.to_sym || @severity_threshold
    end
  end
end
