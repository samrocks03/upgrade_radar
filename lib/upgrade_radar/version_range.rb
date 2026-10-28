# frozen_string_literal: true

module UpgradeRadar
  class VersionRange
    attr_reader :framework, :version

    VALID_FRAMEWORKS = %w[rails ruby].freeze

    def initialize(descriptor)
      parts = descriptor.strip.split("-", 2)
      raise ArgumentError, "Invalid version descriptor: #{descriptor.inspect}. Expected format: 'rails-7.2' or 'ruby-3.3'" unless parts.length == 2

      @framework = parts[0].downcase
      raise ArgumentError, "Unknown framework: #{@framework.inspect}. Supported: #{VALID_FRAMEWORKS.join(', ')}" unless VALID_FRAMEWORKS.include?(@framework)

      @version = Gem::Version.new(parts[1])
    rescue ArgumentError => e
      raise e if e.message.start_with?("Invalid version", "Unknown framework")
      raise ArgumentError, "Invalid version number in: #{descriptor.inspect}"
    end

    def self.parse(from_str, to_str)
      from = new(from_str)
      to = new(to_str)
      unless from.framework == to.framework
        raise ArgumentError, "Framework mismatch: --from is #{from.framework} but --to is #{to.framework}"
      end
      unless to.version > from.version
        raise ArgumentError, "--to version (#{to.version}) must be greater than --from version (#{from.version})"
      end
      [from, to]
    end

    def to_s
      "#{framework}-#{version}"
    end
  end
end
