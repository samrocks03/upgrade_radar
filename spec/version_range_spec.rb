# frozen_string_literal: true

RSpec.describe UpgradeRadar::VersionRange do
  describe "#initialize" do
    it "parses rails version" do
      vr = described_class.new("rails-7.2")
      expect(vr.framework).to eq("rails")
      expect(vr.version).to eq(Gem::Version.new("7.2"))
    end

    it "parses ruby version" do
      vr = described_class.new("ruby-3.4")
      expect(vr.framework).to eq("ruby")
      expect(vr.version).to eq(Gem::Version.new("3.4"))
    end

    it "raises on invalid format" do
      expect { described_class.new("invalid") }.to raise_error(ArgumentError)
    end

    it "raises on unknown framework" do
      expect { described_class.new("django-4.0") }.to raise_error(ArgumentError, /Unknown framework/)
    end
  end

  describe ".parse" do
    it "returns from and to ranges" do
      from, to = described_class.parse("rails-7.2", "rails-8.0")
      expect(from.framework).to eq("rails")
      expect(to.version).to eq(Gem::Version.new("8.0"))
    end

    it "raises on framework mismatch" do
      expect { described_class.parse("rails-7.2", "ruby-3.4") }.to raise_error(ArgumentError, /mismatch/)
    end

    it "raises when to <= from" do
      expect { described_class.parse("rails-8.0", "rails-7.2") }.to raise_error(ArgumentError, /must be greater/)
    end
  end

  describe "#to_s" do
    it "formats as framework-version" do
      expect(described_class.new("rails-7.2").to_s).to eq("rails-7.2")
    end
  end
end
