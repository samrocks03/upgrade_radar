# frozen_string_literal: true

RSpec.describe UpgradeRadar::Formatters::JsonFormatter do
  let(:formatter) { described_class.new }

  it "produces valid JSON" do
    result = UpgradeRadar::Result.new(
      findings: [],
      files_scanned: 5,
      scan_duration: 0.1,
      from_version: UpgradeRadar::VersionRange.new("rails-7.2"),
      to_version: UpgradeRadar::VersionRange.new("rails-8.0")
    )
    output = formatter.format(result)
    parsed = JSON.parse(output)
    expect(parsed).to have_key("metadata")
    expect(parsed).to have_key("summary")
    expect(parsed).to have_key("findings")
    expect(parsed["metadata"]["from"]).to eq("rails-7.2")
  end
end
