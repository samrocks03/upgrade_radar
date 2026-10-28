# frozen_string_literal: true

module UpgradeRadar
  module Matchers
    class StringMutationMatcher < Base
      MUTATING_METHODS = %i[<< replace gsub! sub! clear []= capitalize! chomp!
                            chop! delete! downcase! encode! lstrip! rstrip!
                            strip! squeeze! swapcase! tr! tr_s! upcase!
                            prepend setbyte unicode_normalize!].freeze

      def match?(node, **_opts)
        return false unless node.is_a?(Prism::CallNode)
        return false unless MUTATING_METHODS.include?(node.name)
        return false unless string_literal_receiver?(node.receiver)
        true
      end

      private

      def string_literal_receiver?(receiver)
        case receiver
        when Prism::StringNode, Prism::InterpolatedStringNode
          true
        when Prism::ParenthesesNode
          receiver.body&.body&.first.is_a?(Prism::StringNode)
        else
          false
        end
      end
    end
  end
end
