# frozen_string_literal: true

RSpec.describe UpgradeRadar::EffortEstimator do
  def build_result(effort_values)
    rules = effort_values.map.with_index do |effort, i|
      UpgradeRadar::Rule.new(
        "id" => "rule-#{i}", "framework" => "rails",
        "introduced_in" => "7.1", "breaking_in" => "8.0",
        "pattern" => { "type" => "method_call" },
        "message" => "msg", "effort_minutes" => effort
      )
    end
    findings = rules.map do |r|
      UpgradeRadar::Finding.new(
        rule: r, filepath: "test.rb", line: 1, column: 0,
        source: "code", severity: :breaking
      )
    end
    UpgradeRadar::Result.new(findings: findings, files_scanned: 1, scan_duration: 0.1)
  end

  it "computes total effort" do
    result = build_result([5, 10, 15])
    summary = described_class.new(result).summary
    expect(summary[:total_effort_minutes]).to eq(30)
  end

  it "humanizes minutes" do
    result = build_result([5])
    summary = described_class.new(result).summary
    expect(summary[:total_effort_human]).to eq("5 minutes")
  end

  it "humanizes hours" do
    result = build_result([120])
    summary = described_class.new(result).summary
    expect(summary[:total_effort_human]).to include("hours")
  end

  it "classifies effort level" do
    trivial = described_class.new(build_result([5])).summary
    expect(trivial[:effort_level]).to eq(:trivial)

    large = described_class.new(build_result([500])).summary
    expect(large[:effort_level]).to eq(:large)
  end
end
