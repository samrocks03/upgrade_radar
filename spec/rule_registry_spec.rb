# frozen_string_literal: true

RSpec.describe UpgradeRadar::RuleRegistry do
  subject { described_class.new.load_builtin_rules }

  describe "#load_builtin_rules" do
    it "loads rules from YAML files" do
      expect(subject.rules).not_to be_empty
    end

    it "has no duplicate rule IDs" do
      ids = subject.rules.map(&:id)
      expect(ids).to eq(ids.uniq)
    end
  end

  describe "#rules_for" do
    it "returns Rails rules for Rails version range" do
      from = UpgradeRadar::VersionRange.new("rails-7.0")
      to = UpgradeRadar::VersionRange.new("rails-8.0")
      rules = subject.rules_for(from, to)
      expect(rules).not_to be_empty
      expect(rules.map(&:framework).uniq).to eq(["rails"])
    end

    it "returns Ruby rules for Ruby version range" do
      from = UpgradeRadar::VersionRange.new("ruby-3.2")
      to = UpgradeRadar::VersionRange.new("ruby-3.4")
      rules = subject.rules_for(from, to)
      expect(rules).not_to be_empty
      expect(rules.map(&:framework).uniq).to eq(["ruby"])
    end

    it "returns empty for version range with no matching rules" do
      from = UpgradeRadar::VersionRange.new("rails-5.0")
      to = UpgradeRadar::VersionRange.new("rails-5.1")
      rules = subject.rules_for(from, to)
      expect(rules).to be_empty
    end
  end
end
