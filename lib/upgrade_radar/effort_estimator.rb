# frozen_string_literal: true

module UpgradeRadar
  class EffortEstimator
    EFFORT_LABELS = {
      trivial: 0..30,
      small: 31..120,
      medium: 121..480,
      large: 481..Float::INFINITY
    }.freeze

    def initialize(result)
      @result = result
    end

    def summary
      total = @result.total_effort_minutes
      {
        total_findings: @result.findings.size,
        breaking: @result.breaking_count,
        warnings: @result.warning_count,
        files_affected: @result.affected_files_count,
        total_effort_minutes: total,
        total_effort_human: humanize_minutes(total),
        effort_level: effort_level(total),
        by_rule: effort_by_rule
      }
    end

    private

    def effort_level(minutes)
      EFFORT_LABELS.each do |label, range|
        return label if range.include?(minutes)
      end
      :large
    end

    def effort_by_rule
      @result.findings_by_rule.transform_values do |findings|
        {
          count: findings.size,
          total_minutes: findings.sum(&:effort_minutes),
          severity: findings.first.severity
        }
      end
    end

    def humanize_minutes(minutes)
      return "none" if minutes == 0

      if minutes < 60
        "#{minutes} minutes"
      elsif minutes < 480
        hours = (minutes / 60.0).round(1)
        "~#{hours} hours"
      else
        days = (minutes / 480.0).round(1)
        "~#{days} days"
      end
    end
  end
end
