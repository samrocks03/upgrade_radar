# frozen_string_literal: true

module UpgradeRadar
  module Formatters
    class JsonFormatter < Base
      def format(result)
        estimator = EffortEstimator.new(result)

        data = {
          metadata: {
            upgrade_radar_version: UpgradeRadar::VERSION,
            from: result.from_version&.to_s,
            to: result.to_version&.to_s,
            scanned_at: Time.now.strftime("%Y-%m-%dT%H:%M:%S%z"),
            scan_duration_seconds: result.scan_duration.round(3),
            files_scanned: result.files_scanned
          },
          summary: estimator.summary,
          findings: result.findings.map(&:to_h)
        }

        JSON.pretty_generate(data)
      end
    end
  end
end
