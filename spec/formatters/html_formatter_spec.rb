# frozen_string_literal: true

RSpec.describe UpgradeRadar::Formatters::HtmlFormatter do
  let(:formatter) { described_class.new }

  it "produces valid HTML" do
    result = UpgradeRadar::Result.new(
      findings: [],
      files_scanned: 5,
      scan_duration: 0.1,
      from_version: UpgradeRadar::VersionRange.new("rails-7.2"),
      to_version: UpgradeRadar::VersionRange.new("rails-8.0")
    )
    output = formatter.format(result)
    expect(output).to include("<!DOCTYPE html>")
    expect(output).to include("Upgrade Radar Report")
    expect(output).to include("rails-7.2")
  end

  it "escapes scanned source code" do
    rule = UpgradeRadar::Rule.new(
      "id" => "test-rule", "framework" => "ruby", "introduced_in" => "3.4", "breaking_in" => "3.4",
      "pattern" => { "type" => "string_mutation" }, "message" => "Uses <b>", "replacement" => "a & b",
      "docs" => "https://example.com/?a=1&b=\"2\""
    )
    finding = UpgradeRadar::Finding.new(
      rule: rule, filepath: "app/<evil>.rb", line: 1, column: 0,
      source: '"<script>alert(1)</script>".gsub!("a", "b")', severity: :breaking
    )
    result = UpgradeRadar::Result.new(findings: [finding], files_scanned: 1, scan_duration: 0.1)
    output = formatter.format(result)

    expect(output).not_to include("<script>")
    expect(output).to include("&lt;script&gt;alert(1)&lt;/script&gt;")
    expect(output).to include("app/&lt;evil&gt;.rb")
    expect(output).to include("Uses &lt;b&gt;")
    expect(output).to include("a &amp; b")
    expect(output).to include('href="https://example.com/?a=1&amp;b=&quot;2&quot;"')
  end
end
