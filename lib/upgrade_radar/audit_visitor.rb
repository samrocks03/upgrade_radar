# frozen_string_literal: true

module UpgradeRadar
  class AuditVisitor < Prism::Visitor
    attr_reader :findings

    def initialize(filepath, rules, to_version)
      super()
      @filepath = filepath
      @to_version = to_version
      @findings = []
      @context_stack = []
      @in_parameterless_block = false

      @call_node_rules = rules.select { |r| r.node_types.include?(:call_node) }
      @constant_rules = rules.select { |r| r.node_types.include?(:constant_read_node) || r.node_types.include?(:constant_path_node) }

      @matchers = build_matchers(rules)
    end

    def visit_call_node(node)
      @call_node_rules.each do |rule|
        matcher = @matchers[rule.id]
        next unless matcher

        matched = if rule.pattern["type"] == "block_parameter"
                    matcher.match?(node, in_parameterless_block: @in_parameterless_block)
                  else
                    matcher.match?(node)
                  end

        if matched
          @findings << Finding.new(
            rule: rule,
            filepath: @filepath,
            line: node.location.start_line,
            column: node.location.start_column,
            source: node.location.slice,
            severity: rule.severity_for(@to_version)
          )
        end
      end
      super
    end

    def visit_constant_read_node(node)
      check_constant_node(node)
      super
    end

    def visit_constant_path_node(node)
      check_constant_node(node)
      super
    end

    def visit_it_local_variable_read_node(node)
      @call_node_rules.each do |rule|
        next unless rule.pattern["type"] == "block_parameter"
        matcher = @matchers[rule.id]
        next unless matcher

        if matcher.match?(node, in_parameterless_block: @in_parameterless_block)
          @findings << Finding.new(
            rule: rule,
            filepath: @filepath,
            line: node.location.start_line,
            column: node.location.start_column,
            source: node.location.slice,
            severity: rule.severity_for(@to_version)
          )
        end
      end
      super
    end

    def visit_rescue_node(node)
      @context_stack.push(:rescue)
      super
      @context_stack.pop
    end

    def visit_block_node(node)
      previous = @in_parameterless_block
      @in_parameterless_block = node.parameters.nil? || node.parameters.is_a?(Prism::ItParametersNode)
      super
      @in_parameterless_block = previous
    end

    def visit_lambda_node(node)
      previous = @in_parameterless_block
      @in_parameterless_block = node.parameters.nil? || node.parameters.is_a?(Prism::ItParametersNode)
      super
      @in_parameterless_block = previous
    end

    private

    def check_constant_node(node)
      @constant_rules.each do |rule|
        matcher = @matchers[rule.id]
        next unless matcher

        if matcher.match?(node, context: @context_stack.last)
          @findings << Finding.new(
            rule: rule,
            filepath: @filepath,
            line: node.location.start_line,
            column: node.location.start_column,
            source: node.location.slice,
            severity: rule.severity_for(@to_version)
          )
        end
      end
    end

    def build_matchers(rules)
      rules.reject { |r| r.pattern["type"] == "gemfile_dependency" }
           .each_with_object({}) { |rule, hash| hash[rule.id] = Matchers::Base.for(rule.pattern) }
    end
  end
end
