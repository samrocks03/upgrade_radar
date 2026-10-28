# frozen_string_literal: true

module UpgradeRadar
  class Scanner
    def initialize(from:, to:, config:)
      @from = from
      @to = to
      @config = config
      @registry = RuleRegistry.new
    end

    def run
      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      @registry.load_builtin_rules
      @registry.load_custom_rules(@config.custom_rules_path) if @config.custom_rules_path

      active_rules = @registry.rules_for(@from, @to)
      ast_rules = active_rules.reject { |r| r.pattern["type"] == "gemfile_dependency" }
      gemfile_rules = active_rules.select { |r| r.pattern["type"] == "gemfile_dependency" }

      finder = FileFinder.new(@config.scan_path, exclude_patterns: @config.exclude_patterns)
      ruby_files = finder.ruby_files
      findings = []

      ruby_files.each do |filepath|
        scan_file(filepath, ast_rules, findings)
      end

      check_gemfile(gemfile_rules, finder, ruby_files, findings)

      elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time

      Result.new(
        findings: findings,
        files_scanned: ruby_files.size,
        scan_duration: elapsed,
        from_version: @from,
        to_version: @to
      )
    end

    private

    def scan_file(filepath, rules, findings)
      parse_result = Prism.parse_file(filepath)
      visitor = AuditVisitor.new(filepath, rules, @to.version)
      visitor.visit(parse_result.value)
      findings.concat(visitor.findings)
    rescue => e
      $stderr.puts "upgrade_radar: error scanning #{filepath}: #{e.message}"
    end

    def check_gemfile(gemfile_rules, finder, ruby_files, findings)
      gemfile_rules.each do |rule|
        matcher = Matchers::GemfileMatcher.new(rule.pattern)
        missing = matcher.check_gemfile(finder.gemfile_path, ruby_files)
        missing.each do |gem_name|
          findings << Finding.new(
            rule: rule,
            filepath: finder.gemfile_path || "Gemfile",
            line: 1,
            column: 0,
            source: "missing: gem '#{gem_name}'",
            severity: rule.severity_for(@to.version)
          )
        end
      end
    end
  end
end
