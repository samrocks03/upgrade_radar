# frozen_string_literal: true

require_relative "collector"
require_relative "rails_hook"
require_relative "ruby_warning_hook"

module UpgradeRadar
  module Runtime
    class Middleware
      attr_reader :collector

      def initialize(app, collector: nil)
        @app = app
        @collector = collector || Collector.new
      end

      def call(env)
        @app.call(env)
      end

      def self.setup_for_rspec(collector = nil)
        collector ||= Collector.new

        RSpec.configure do |config|
          config.before(:suite) do
            RailsHook.install(collector)
            RubyWarningHook.install(collector)
          end

          config.after(:suite) do
            if collector.size > 0
              $stderr.puts "\n\nUpgrade Radar: #{collector.size} runtime deprecation(s) captured"
              collector.to_findings.each do |f|
                $stderr.puts "  #{f.filepath}:#{f.line} #{f.message}"
              end
            end
          end
        end

        collector
      end

      def self.setup_for_minitest(collector = nil)
        collector ||= Collector.new
        RailsHook.install(collector)
        RubyWarningHook.install(collector)
        collector
      end
    end
  end
end
