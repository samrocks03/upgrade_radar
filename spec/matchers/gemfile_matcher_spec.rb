# frozen_string_literal: true

RSpec.describe UpgradeRadar::Matchers::GemfileMatcher do
  let(:pattern) { { "type" => "gemfile_dependency", "gems" => %w[csv base64 bigdecimal] } }
  let(:matcher) { described_class.new(pattern) }

  describe "#check_gemfile" do
    it "reports missing gems that are required in code" do
      missing = matcher.check_gemfile(
        fixture_path("sample_gemfile.rb"),
        [fixture_path("default_gems.rb")]
      )
      expect(missing).to include("csv", "base64", "bigdecimal")
    end

    it "returns empty when no gems are used" do
      missing = matcher.check_gemfile(
        fixture_path("sample_gemfile.rb"),
        [fixture_path("clean_file.rb")]
      )
      expect(missing).to be_empty
    end
  end
end
