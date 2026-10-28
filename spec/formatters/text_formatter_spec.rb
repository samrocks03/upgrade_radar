# frozen_string_literal: true

RSpec.describe UpgradeRadar::Formatters::TextFormatter do
  let(:formatter) { described_class.new }

  def build_result(findings: [])
    UpgradeRadar::Result.new(
      findings: findings,
      files_scanned: 10,
      scan_duration: 0.5,
      from_version: UpgradeRadar::VersionRange.new("rails-7.2"),
      to_version: UpgradeRadar::VersionRange.new("rails-8.0")
    )
  end

  it "formats empty results" do
    output = formatter.format(build_result)
    expect(output).to include("No deprecations")
    expect(output).to include("UPGRADE SUMMARY")
  end

  it "formats results with findings" do
    rule = UpgradeRadar::Rule.new(
      "id" => "test", "framework" => "rails",
      "introduced_in" => "7.1", "breaking_in" => "8.0",
      "pattern" => { "type" => "method_call" },
      "message" => "Test deprecation message",
      "replacement" => "Use new API"
    )
    finding = UpgradeRadar::Finding.new(
      rule: rule, filepath: "app/models/user.rb",
      line: 42, column: 4, source: "serialize :tags, Array",
      severity: :breaking
    )
    output = formatter.format(build_result(findings: [finding]))
    expect(output).to include("BREAKS")
    expect(output).to include("Line 42")
    expect(output).to include("Test deprecation message")
  end
end
