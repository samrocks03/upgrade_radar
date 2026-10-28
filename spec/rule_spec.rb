# frozen_string_literal: true

RSpec.describe UpgradeRadar::Rule do
  let(:attrs) do
    {
      "id" => "test-rule",
      "framework" => "rails",
      "introduced_in" => "7.1",
      "breaking_in" => "8.0",
      "pattern" => { "type" => "method_call", "name" => "serialize" },
      "message" => "Test message",
      "replacement" => "Do this instead",
      "docs" => "https://example.com",
      "effort_minutes" => 5
    }
  end

  subject { described_class.new(attrs) }

  describe "#applies?" do
    it "applies when in version range" do
      expect(subject.applies?(Gem::Version.new("7.0"), Gem::Version.new("8.0"))).to be true
    end

    it "does not apply when already broken before from" do
      rule = described_class.new(attrs.merge("introduced_in" => "6.0", "breaking_in" => "6.1"))
      expect(rule.applies?(Gem::Version.new("7.0"), Gem::Version.new("8.0"))).to be false
    end

    it "does not apply when introduced after to" do
      rule = described_class.new(attrs.merge("introduced_in" => "9.0", "breaking_in" => "10.0"))
      expect(rule.applies?(Gem::Version.new("7.0"), Gem::Version.new("8.0"))).to be false
    end
  end

  describe "#severity_for" do
    it "returns :breaking when to >= breaking_in" do
      expect(subject.severity_for(Gem::Version.new("8.0"))).to eq(:breaking)
    end

    it "returns :warning when to < breaking_in" do
      expect(subject.severity_for(Gem::Version.new("7.2"))).to eq(:warning)
    end

    it "never returns :breaking for low-confidence rules" do
      rule = described_class.new(attrs.merge("confidence" => "low"))
      expect(rule.severity_for(Gem::Version.new("8.0"))).to eq(:warning)
    end
  end

  describe "#node_types" do
    it "returns :call_node for method_call pattern" do
      expect(subject.node_types).to eq([:call_node])
    end

    it "returns constant types for constant_reference pattern" do
      rule = described_class.new(attrs.merge("pattern" => { "type" => "constant_reference" }))
      expect(rule.node_types).to include(:constant_read_node, :constant_path_node)
    end
  end
end
