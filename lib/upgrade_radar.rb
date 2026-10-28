# frozen_string_literal: true

require "prism"
require "yaml"
require "json"
require "erb"

require_relative "upgrade_radar/version"
require_relative "upgrade_radar/version_range"
require_relative "upgrade_radar/rule"
require_relative "upgrade_radar/rule_registry"
require_relative "upgrade_radar/finding"
require_relative "upgrade_radar/result"
require_relative "upgrade_radar/effort_estimator"
require_relative "upgrade_radar/file_finder"
require_relative "upgrade_radar/matchers/base"
require_relative "upgrade_radar/matchers/method_call_matcher"
require_relative "upgrade_radar/matchers/constant_reference_matcher"
require_relative "upgrade_radar/matchers/block_parameter_matcher"
require_relative "upgrade_radar/matchers/gemfile_matcher"
require_relative "upgrade_radar/matchers/string_mutation_matcher"
require_relative "upgrade_radar/audit_visitor"
require_relative "upgrade_radar/scanner"
require_relative "upgrade_radar/formatters/base"
require_relative "upgrade_radar/formatters/text_formatter"
require_relative "upgrade_radar/formatters/json_formatter"
require_relative "upgrade_radar/formatters/html_formatter"
require_relative "upgrade_radar/configuration"
require_relative "upgrade_radar/cli"

module UpgradeRadar
  RULES_PATH = File.expand_path("../../rules", __FILE__)
end
