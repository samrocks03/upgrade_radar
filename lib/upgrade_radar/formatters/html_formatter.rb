# frozen_string_literal: true

module UpgradeRadar
  module Formatters
    class HtmlFormatter < Base
      include ERB::Util

      TEMPLATE_PATH = File.expand_path("../templates/report.html.erb", __dir__)

      def format(result)
        @result = result
        @estimator = EffortEstimator.new(result)
        @summary = @estimator.summary
        template = File.read(TEMPLATE_PATH)
        erb = ERB.new(template, trim_mode: "-")
        erb.result(binding)
      end
    end
  end
end
