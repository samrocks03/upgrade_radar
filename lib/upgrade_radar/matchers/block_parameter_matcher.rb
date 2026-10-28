# frozen_string_literal: true

module UpgradeRadar
  module Matchers
    class BlockParameterMatcher < Base
      def match?(node, in_parameterless_block: false, **_opts)
        return false unless in_parameterless_block
        if node.is_a?(Prism::ItLocalVariableReadNode)
          return true
        end
        return false unless node.is_a?(Prism::CallNode)
        return false unless node.name == :it
        return false unless node.receiver.nil?
        return false if node.arguments && !node.arguments.arguments.empty?
        true
      end
    end
  end
end
