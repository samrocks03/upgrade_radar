# frozen_string_literal: true

module UpgradeRadar
  module Formatters
    class Base
      def format(_result)
        raise NotImplementedError
      end

      def self.for(format_name)
        case format_name.to_s
        when "text" then TextFormatter.new
        when "json" then JsonFormatter.new
        when "html" then HtmlFormatter.new
        else raise ArgumentError, "Unknown format: #{format_name}. Supported: text, json, html"
        end
      end
    end
  end
end
