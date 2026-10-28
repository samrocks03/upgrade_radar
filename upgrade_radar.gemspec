# frozen_string_literal: true

require_relative "lib/upgrade_radar/version"

Gem::Specification.new do |spec|
  spec.name          = "upgrade_radar"
  spec.version       = UpgradeRadar::VERSION
  spec.authors       = ["Samarth Kulkarni"]
  spec.email         = ["svkulkarni23@gmail.com"]

  spec.summary       = "Know your Ruby/Rails upgrade cost before you start"
  spec.description   = "Static and runtime analysis for Ruby/Rails deprecations and breaking changes. " \
                        "Scans your codebase with Prism AST analysis and reports what will break, where, and why."
  spec.homepage      = "https://github.com/samrocks03/upgrade_radar"
  spec.license       = "MIT"

  spec.required_ruby_version = ">= 3.2.0"

  spec.files         = Dir["lib/**/*", "exe/*", "rules/**/*", "LICENSE.txt", "README.md", "CHANGELOG.md"]
  spec.bindir        = "exe"
  spec.executables   = ["upgrade_radar"]
  spec.require_paths = ["lib"]

  spec.add_dependency "prism", "~> 1.0"
  spec.add_dependency "thor", "~> 1.3"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"] = "#{spec.homepage}/issues"
  spec.metadata["rubygems_mfa_required"] = "true"
end
