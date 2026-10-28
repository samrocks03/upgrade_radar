# frozen_string_literal: true

module UpgradeRadar
  module Matchers
    class GemfileMatcher < Base
      def initialize(pattern)
        super
        @required_gems = pattern["gems"] || []
      end

      def match?(_node, **_opts)
        false
      end

      def check_gemfile(gemfile_path, ruby_files)
        return [] unless gemfile_path && File.exist?(gemfile_path)

        declared = extract_gem_declarations(gemfile_path)
        missing = []

        @required_gems.each do |gem_name|
          next if declared.include?(gem_name)
          next unless used_in_code?(gem_name, ruby_files)
          missing << gem_name
        end

        missing
      end

      private

      def extract_gem_declarations(gemfile_path)
        content = File.read(gemfile_path)
        result = Prism.parse(content)
        gems = Set.new

        visitor = GemfileVisitor.new
        visitor.visit(result.value)
        gems.merge(visitor.gem_names)

        gems
      end

      def used_in_code?(gem_name, ruby_files)
        ruby_files.any? do |f|
          content = File.read(f)
          content.include?("require \"#{gem_name}\"") ||
            content.include?("require '#{gem_name}'")
        end
      end

      class GemfileVisitor < Prism::Visitor
        attr_reader :gem_names

        def initialize
          super
          @gem_names = Set.new
        end

        def visit_call_node(node)
          if node.name == :gem && node.receiver.nil?
            first_arg = node.arguments&.arguments&.first
            @gem_names << first_arg.unescaped if first_arg.is_a?(Prism::StringNode)
          end
          super
        end
      end
    end
  end
end
