# frozen_string_literal: true

module UpgradeRadar
  module Matchers
    class ConstantReferenceMatcher < Base
      def initialize(pattern)
        super
        @expected_name = pattern["name"]
        @context = pattern["context"]
      end

      def match?(node, context: nil, **_opts)
        return false unless constant_name(node) == @expected_name
        return false if @context == "rescue" && context != :rescue
        true
      end

      private

      def constant_name(node)
        case node
        when Prism::ConstantReadNode
          node.name.to_s
        when Prism::ConstantPathNode
          build_constant_path(node)
        else
          nil
        end
      end

      def build_constant_path(node)
        parts = []
        current = node
        while current.is_a?(Prism::ConstantPathNode)
          parts.unshift(current.name.to_s)
          current = current.parent
        end
        parts.unshift(current.name.to_s) if current.is_a?(Prism::ConstantReadNode)
        parts.join("::")
      end
    end
  end
end
