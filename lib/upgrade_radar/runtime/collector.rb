# frozen_string_literal: true

module UpgradeRadar
  module Runtime
    class Collector
      attr_reader :warnings

      def initialize
        @warnings = []
        @mutex = Mutex.new
        @seen = Set.new
      end

      def add(message, source: nil, backtrace: nil)
        key = message.strip
        @mutex.synchronize do
          return if @seen.include?(key)
          @seen << key
          @warnings << {
            message: key,
            source: source,
            backtrace: backtrace&.first(5)&.map(&:to_s),
            timestamp: Time.now
          }
        end
      end

      def to_findings
        @warnings.map do |w|
          location = parse_location(w[:backtrace]&.first)
          RuntimeFinding.new(
            message: w[:message],
            source: w[:source],
            filepath: location[:file],
            line: location[:line]
          )
        end
      end

      def size
        @warnings.size
      end

      def clear
        @mutex.synchronize do
          @warnings.clear
          @seen.clear
        end
      end

      private

      def parse_location(backtrace_line)
        return { file: nil, line: nil } unless backtrace_line
        if backtrace_line =~ /\A(.+):(\d+)/
          { file: $1, line: $2.to_i }
        else
          { file: nil, line: nil }
        end
      end
    end

    class RuntimeFinding
      attr_reader :message, :source, :filepath, :line

      def initialize(message:, source:, filepath:, line:)
        @message = message
        @source = source
        @filepath = filepath
        @line = line
      end
    end
  end
end
