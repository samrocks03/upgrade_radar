# frozen_string_literal: true

module UpgradeRadar
  module Formatters
    class TextFormatter < Base
      COLORS = {
        red: "\e[31m",
        yellow: "\e[33m",
        green: "\e[32m",
        bold: "\e[1m",
        dim: "\e[2m",
        reset: "\e[0m"
      }.freeze

      def format(result)
        output = []

        output << header(result)
        output << ""

        if result.findings.empty?
          output << colorize("  No deprecations or breaking changes found!", :green)
        else
          result.findings_by_file.each do |filepath, findings|
            output << colorize(filepath, :bold)
            findings.sort_by(&:line).each do |f|
              output << format_finding(f)
            end
            output << ""
          end
        end

        output << effort_summary(result)
        output.join("\n")
      end

      private

      def header(result)
        lines = []
        lines << colorize("Upgrade Radar v#{UpgradeRadar::VERSION}", :bold)
        if result.from_version && result.to_version
          lines << "Scanning for: #{result.from_version} → #{result.to_version}"
        end
        lines << "Files scanned: #{result.files_scanned}"
        lines.join("\n")
      end

      def format_finding(finding)
        badge = if finding.severity == :breaking
                  colorize("[BREAKS]", :red)
                else
                  colorize("[WARN]  ", :yellow)
                end

        lines = []
        lines << "  #{badge} Line #{finding.line}: #{finding.message}"
        lines << "    #{colorize('Source:', :dim)} #{truncate(finding.source, 100)}"
        lines << "    #{colorize('Fix:', :dim)} #{finding.rule.replacement}" if finding.rule.replacement
        lines << "    #{colorize('Docs:', :dim)} #{finding.rule.docs}" if finding.rule.docs
        lines.join("\n")
      end

      def effort_summary(result)
        estimator = EffortEstimator.new(result)
        summary = estimator.summary

        lines = []
        lines << colorize("=" * 60, :dim)
        lines << colorize("UPGRADE SUMMARY", :bold)
        lines << colorize("=" * 60, :dim)
        lines << "  Total findings:  #{summary[:total_findings]}"
        lines << "  Breaking:        #{colorize(summary[:breaking].to_s, summary[:breaking] > 0 ? :red : :green)}"
        lines << "  Warnings:        #{colorize(summary[:warnings].to_s, summary[:warnings] > 0 ? :yellow : :green)}"
        lines << "  Files affected:  #{summary[:files_affected]}"
        lines << "  Estimated effort: #{colorize(summary[:total_effort_human], :bold)} (#{summary[:effort_level]})"
        lines << ""
        lines << "  Scan completed in #{result.scan_duration.round(2)}s"
        lines.join("\n")
      end

      def colorize(text, color)
        if $stdout.tty?
          "#{COLORS[color]}#{text}#{COLORS[:reset]}"
        else
          text
        end
      end

      def truncate(text, max)
        clean = text.gsub(/\s+/, " ")
        clean.length > max ? "#{clean[0...max]}..." : clean
      end
    end
  end
end
