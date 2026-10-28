# frozen_string_literal: true

RSpec.describe UpgradeRadar::Matchers::BlockParameterMatcher do
  let(:pattern) { { "type" => "block_parameter", "bare_it" => true } }
  let(:matcher) { described_class.new(pattern) }

  def find_it_nodes(code)
    result = Prism.parse(code)
    collector = ItNodeCollector.new
    collector.visit(result.value)
    collector.nodes
  end

  it "matches bare it in parameterless block" do
    nodes = find_it_nodes("items.map { it.to_s }")
    expect(nodes.size).to be >= 1
    expect(matcher.match?(nodes.first, in_parameterless_block: true)).to be true
  end

  it "does not match when not in parameterless block" do
    nodes = find_it_nodes("items.map { it.to_s }")
    expect(nodes.size).to be >= 1
    expect(matcher.match?(nodes.first, in_parameterless_block: false)).to be false
  end

  it "does not match it with arguments (as method call)" do
    calls = find_call_nodes("items.map { it(42) }")
    it_calls = calls.select { |c| c.name == :it }
    if it_calls.any?
      expect(matcher.match?(it_calls.first, in_parameterless_block: true)).to be false
    end
  end
end

class ItNodeCollector < Prism::Visitor
  attr_reader :nodes

  def initialize
    super
    @nodes = []
  end

  def visit_it_local_variable_read_node(node)
    @nodes << node
    super
  end

  def visit_call_node(node)
    @nodes << node if node.name == :it && node.receiver.nil?
    super
  end
end
