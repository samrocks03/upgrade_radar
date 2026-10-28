# frozen_string_literal: true

RSpec.describe UpgradeRadar::Matchers::ConstantReferenceMatcher do
  describe "ActiveSupport::ProxyObject detection" do
    let(:pattern) { { "type" => "constant_reference", "name" => "ActiveSupport::ProxyObject" } }
    let(:matcher) { described_class.new(pattern) }

    it "matches ActiveSupport::ProxyObject reference" do
      result = Prism.parse("class Foo < ActiveSupport::ProxyObject; end")
      constants = []
      collector = ConstantPathCollector.new
      collector.visit(result.value)
      matches = collector.nodes.select { |n| matcher.match?(n) }
      expect(matches.size).to eq(1)
    end

    it "does not match ActiveSupport::BasicObject" do
      result = Prism.parse("class Foo < ActiveSupport::BasicObject; end")
      collector = ConstantPathCollector.new
      collector.visit(result.value)
      matches = collector.nodes.select { |n| matcher.match?(n) }
      expect(matches).to be_empty
    end
  end

  describe "SocketError in rescue context" do
    let(:pattern) { { "type" => "constant_reference", "name" => "SocketError", "context" => "rescue" } }
    let(:matcher) { described_class.new(pattern) }

    it "matches SocketError when context is rescue" do
      result = Prism.parse("begin; rescue SocketError; end")
      collector = ConstantReadCollector.new
      collector.visit(result.value)
      matches = collector.nodes.select { |n| matcher.match?(n, context: :rescue) }
      expect(matches.size).to eq(1)
    end

    it "does not match SocketError outside rescue context" do
      result = Prism.parse("SocketError")
      collector = ConstantReadCollector.new
      collector.visit(result.value)
      matches = collector.nodes.select { |n| matcher.match?(n, context: nil) }
      expect(matches).to be_empty
    end
  end
end

class ConstantPathCollector < Prism::Visitor
  attr_reader :nodes

  def initialize
    super
    @nodes = []
  end

  def visit_constant_path_node(node)
    @nodes << node
    super
  end
end

class ConstantReadCollector < Prism::Visitor
  attr_reader :nodes

  def initialize
    super
    @nodes = []
  end

  def visit_constant_read_node(node)
    @nodes << node
    super
  end
end
