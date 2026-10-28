# frozen_string_literal: true

RSpec.describe UpgradeRadar::Scanner do
  def scan(from:, to:, path: FIXTURES_PATH)
    from_range, to_range = UpgradeRadar::VersionRange.parse(from, to)
    config = UpgradeRadar::Configuration.new(path: path)
    scanner = described_class.new(from: from_range, to: to_range, config: config)
    scanner.run
  end

  it "scans fixtures and returns results" do
    result = scan(from: "rails-7.0", to: "rails-8.0")
    expect(result).to be_a(UpgradeRadar::Result)
    expect(result.files_scanned).to be > 0
    expect(result.scan_duration).to be > 0
  end

  it "finds Rails deprecations in fixture files" do
    result = scan(from: "rails-7.0", to: "rails-8.0")
    expect(result.findings).not_to be_empty
    expect(result.breaking_count).to be > 0
  end

  it "finds Ruby deprecations in fixture files" do
    result = scan(from: "ruby-3.2", to: "ruby-3.4")
    expect(result.findings).not_to be_empty
  end

  it "returns zero findings for clean files only" do
    require "tmpdir"
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "clean.rb"), "class Foo; def bar; 42; end; end")
      result = scan(from: "rails-7.0", to: "rails-8.0", path: dir)
      expect(result.findings).to be_empty
    end
  end

  it "computes exit code based on breaking findings" do
    result = scan(from: "rails-7.0", to: "rails-8.0")
    expect(result.exit_code).to eq(1)
  end
end
