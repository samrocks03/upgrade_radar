# frozen_string_literal: true

module UpgradeRadar
  class Result
    attr_reader :findings, :files_scanned, :scan_duration, :from_version, :to_version

    def initialize(findings:, files_scanned:, scan_duration:, from_version: nil, to_version: nil)
      @findings = findings
      @files_scanned = files_scanned
      @scan_duration = scan_duration
      @from_version = from_version
      @to_version = to_version
    end

    def breaking_count
      findings.count { |f| f.severity == :breaking }
    end

    def warning_count
      findings.count { |f| f.severity == :warning }
    end

    def findings_by_file
      findings.group_by(&:filepath)
    end

    def findings_by_rule
      findings.group_by(&:id)
    end

    def findings_by_severity
      findings.group_by(&:severity)
    end

    def total_effort_minutes
      findings.sum(&:effort_minutes)
    end

    def affected_files_count
      findings.map(&:filepath).uniq.size
    end

    def exit_code
      breaking_count > 0 ? 1 : 0
    end
  end
end
