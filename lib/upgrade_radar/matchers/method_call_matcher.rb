# frozen_string_literal: true

module UpgradeRadar
  module Matchers
    class MethodCallMatcher < Base
      def initialize(pattern)
        super
        @expected_names = Array(pattern["name"]).map(&:to_sym)
        @receiver_spec = pattern["receiver"]
        @receiver_chain = pattern["receiver_chain"]
        @receiver_method = pattern["receiver_method"]
        @conditions = pattern.fetch("conditions", []) || []
      end

      def match?(node, **_opts)
        return false unless node.is_a?(Prism::CallNode)
        return false unless name_matches?(node)
        return false unless receiver_matches?(node)
        return false unless conditions_match?(node)
        true
      end

      private

      def name_matches?(node)
        @expected_names.include?(node.name)
      end

      def receiver_matches?(node)
        if @receiver_chain
          match_receiver_chain?(node)
        elsif @receiver_method
          match_receiver_method?(node)
        elsif @receiver_spec.nil? || @receiver_spec == "null"
          node.receiver.nil?
        elsif @receiver_spec == "any"
          true
        else
          match_receiver_constant?(node, @receiver_spec)
        end
      end

      def match_receiver_chain?(node)
        chain = @receiver_chain
        if chain.start_with?("**.")
          method_name = chain.sub("**.", "").to_sym
          node.receiver.is_a?(Prism::CallNode) && node.receiver.name == method_name
        else
          resolve_chain(node.receiver) == chain
        end
      end

      def match_receiver_method?(node)
        return false unless node.receiver.is_a?(Prism::CallNode)
        node.receiver.name == @receiver_method.to_sym
      end

      def match_receiver_constant?(node, name)
        return false unless node.receiver
        resolve_constant_name(node.receiver) == name
      end

      def resolve_chain(node)
        return nil unless node

        parts = []
        current = node
        while current.is_a?(Prism::CallNode)
          parts.unshift(current.name.to_s)
          current = current.receiver
        end

        if current.is_a?(Prism::ConstantReadNode)
          parts.unshift(current.name.to_s)
        elsif current.is_a?(Prism::ConstantPathNode)
          parts.unshift(resolve_constant_name(current))
        end

        parts.join(".")
      end

      def resolve_constant_name(node)
        case node
        when Prism::ConstantReadNode
          node.name.to_s
        when Prism::ConstantPathNode
          parts = []
          current = node
          while current.is_a?(Prism::ConstantPathNode)
            parts.unshift(current.name.to_s)
            current = current.parent
          end
          parts.unshift(current.name.to_s) if current.is_a?(Prism::ConstantReadNode)
          parts.join("::")
        else
          node.to_s
        end
      end

      def conditions_match?(node)
        @conditions.all? { |cond| evaluate_condition(cond, node) }
      end

      def evaluate_condition(condition, node)
        key, value = condition.is_a?(Hash) ? condition.first : [condition, true]
        case key
        when "no_keyword"
          !has_keyword_arg?(node, value)
        when "has_block_pass"
          has_block_pass?(node)
        when "first_arg_starts_with"
          first_string_arg_starts_with?(node, value)
        when "first_arg_type"
          first_arg_is_type?(node, value)
        when "keyword_value"
          has_keyword_with_value?(node, value["key"], value["value"])
        when "has_keywords"
          has_any_keywords?(node)
        when "min_positional_args"
          positional_arg_count(node) >= value
        else
          true
        end
      end

      def args_list(node)
        node.arguments&.arguments || []
      end

      def has_keyword_arg?(node, key_name)
        args_list(node).any? do |arg|
          next false unless arg.is_a?(Prism::KeywordHashNode)
          arg.elements.any? do |elem|
            elem.is_a?(Prism::AssocNode) &&
              elem.key.is_a?(Prism::SymbolNode) &&
              elem.key.value == key_name
          end
        end
      end

      def has_block_pass?(node)
        node.block.is_a?(Prism::BlockArgumentNode) ||
          args_list(node).any? { |a| a.is_a?(Prism::BlockArgumentNode) }
      end

      def first_string_arg_starts_with?(node, prefix)
        first = positional_args(node).first
        first.is_a?(Prism::StringNode) && first.unescaped.start_with?(prefix)
      end

      def first_arg_is_type?(node, type_name)
        first = args_list(node).first
        return false unless first

        case type_name
        when "string"
          first.is_a?(Prism::StringNode)
        when "hash"
          first.is_a?(Prism::KeywordHashNode)
        when "symbol"
          first.is_a?(Prism::SymbolNode)
        when "constant"
          first.is_a?(Prism::ConstantReadNode) || first.is_a?(Prism::ConstantPathNode)
        else
          false
        end
      end

      def has_keyword_with_value?(node, key, expected_value)
        args_list(node).any? do |arg|
          next false unless arg.is_a?(Prism::KeywordHashNode)
          arg.elements.any? do |elem|
            next false unless elem.is_a?(Prism::AssocNode)
            next false unless elem.key.is_a?(Prism::SymbolNode) && elem.key.value == key
            case expected_value
            when "nil"
              elem.value.is_a?(Prism::NilNode)
            when "true"
              elem.value.is_a?(Prism::TrueNode)
            when "false"
              elem.value.is_a?(Prism::FalseNode)
            else
              elem.value.is_a?(Prism::StringNode) && elem.value.unescaped == expected_value
            end
          end
        end
      end

      def has_any_keywords?(node)
        args_list(node).any? { |a| a.is_a?(Prism::KeywordHashNode) }
      end

      def positional_args(node)
        args_list(node).reject { |a| a.is_a?(Prism::KeywordHashNode) || a.is_a?(Prism::BlockArgumentNode) }
      end

      def positional_arg_count(node)
        positional_args(node).size
      end
    end
  end
end
