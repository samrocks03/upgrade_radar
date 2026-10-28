# frozen_string_literal: true

module UpgradeRadar
  module Matchers
    class Base
      def self.for(pattern)
        case pattern["type"]
        when "method_call"
          MethodCallMatcher.new(pattern)
        when "constant_reference"
          ConstantReferenceMatcher.new(pattern)
        when "block_parameter"
          BlockParameterMatcher.new(pattern)
        when "gemfile_dependency"
          GemfileMatcher.new(pattern)
        when "string_mutation"
          StringMutationMatcher.new(pattern)
        else
          raise ArgumentError, "Unknown pattern type: #{pattern['type']}"
        end
      end

      def initialize(pattern)
        @pattern = pattern
      end

      def match?(_node, **_opts)
        raise NotImplementedError
      end
    end
  end
end
