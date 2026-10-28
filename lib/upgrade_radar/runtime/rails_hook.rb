# frozen_string_literal: true

module UpgradeRadar
  module Runtime
    class RailsHook
      def self.install(collector)
        return unless defined?(Rails) && Rails.respond_to?(:application) && Rails.application

        if Rails.application.respond_to?(:deprecators)
          Rails.application.deprecators.each do |deprecator|
            original = Array(deprecator.behavior)
            deprecator.behavior = original + [
              ->(message, callstack, *) { collector.add(message, source: :rails, backtrace: callstack) }
            ]
          end
        elsif defined?(ActiveSupport::Deprecation)
          ActiveSupport::Deprecation.behavior = ActiveSupport::Deprecation.behavior + [
            ->(message, callstack, *) { collector.add(message, source: :rails, backtrace: callstack) }
          ]
        end
      end
    end
  end
end
