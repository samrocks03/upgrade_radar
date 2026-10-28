# frozen_string_literal: true

RSpec.describe UpgradeRadar::AuditVisitor do
  let(:registry) { UpgradeRadar::RuleRegistry.new.load_builtin_rules }

  def scan_fixture(filename, from:, to:)
    from_range = UpgradeRadar::VersionRange.new(from)
    to_range = UpgradeRadar::VersionRange.new(to)
    rules = registry.rules_for(from_range, to_range)
    ast_rules = rules.reject { |r| r.pattern["type"] == "gemfile_dependency" }

    filepath = fixture_path(filename)
    parse_result = Prism.parse_file(filepath)
    visitor = described_class.new(filepath, ast_rules, to_range.version)
    visitor.visit(parse_result.value)
    visitor.findings
  end

  context "Rails 7.2 → 8.0" do
    it "detects old-style enum" do
      findings = scan_fixture("old_enum_style.rb", from: "rails-7.0", to: "rails-8.0")
      enum_findings = findings.select { |f| f.id.include?("enum") }
      expect(enum_findings.size).to eq(2)
    end

    it "detects serialize without coder" do
      findings = scan_fixture("serialize_without_coder.rb", from: "rails-7.0", to: "rails-8.0")
      serialize_findings = findings.select { |f| f.id.include?("serialize") }
      expect(serialize_findings.size).to eq(2)
    end

    it "detects connection_pool.connection" do
      findings = scan_fixture("connection_pool_usage.rb", from: "rails-7.2", to: "rails-8.0")
      expect(findings.any? { |f| f.id.include?("connection-pool") }).to be true
    end

    it "detects Rails.application.secrets" do
      findings = scan_fixture("secrets_usage.rb", from: "rails-7.0", to: "rails-8.0")
      secrets_findings = findings.select { |f| f.id.include?("secrets") }
      expect(secrets_findings.size).to eq(2)
    end

    it "detects params.require.permit" do
      findings = scan_fixture("params_permit.rb", from: "rails-7.2", to: "rails-8.0")
      expect(findings.any? { |f| f.id.include?("params") }).to be true
    end

    it "detects ActiveSupport::ProxyObject" do
      findings = scan_fixture("proxy_object_usage.rb", from: "rails-7.2", to: "rails-8.0")
      expect(findings.any? { |f| f.id.include?("proxy-object") }).to be true
    end

    it "detects form_with model: nil" do
      findings = scan_fixture("form_with_nil.rb", from: "rails-7.2", to: "rails-8.0")
      expect(findings.any? { |f| f.id.include?("form-with") }).to be true
    end
  end

  context "Ruby 3.3 → 3.4" do
    it "detects bare it in parameterless blocks" do
      findings = scan_fixture("it_block_param.rb", from: "ruby-3.2", to: "ruby-3.4")
      it_findings = findings.select { |f| f.id.include?("it-block") }
      expect(it_findings.size).to eq(2)
    end

    it "detects lambda(&proc)" do
      findings = scan_fixture("lambda_proc.rb", from: "ruby-3.2", to: "ruby-3.4")
      expect(findings.any? { |f| f.id.include?("lambda") }).to be true
    end

    it "detects IO.read with pipe" do
      findings = scan_fixture("io_pipe.rb", from: "ruby-3.2", to: "ruby-3.4")
      io_findings = findings.select { |f| f.id.include?("io-pipe") }
      expect(io_findings.size).to eq(1)
    end

    it "detects SocketError in rescue" do
      findings = scan_fixture("socket_error.rb", from: "ruby-3.3", to: "ruby-3.4")
      expect(findings.any? { |f| f.id.include?("socket") }).to be true
    end

    it "detects chilled string mutations" do
      findings = scan_fixture("chilled_string.rb", from: "ruby-3.3", to: "ruby-3.4")
      string_findings = findings.select { |f| f.id.include?("chilled-string") }
      expect(string_findings.size).to be >= 2
    end
  end

  context "clean file" do
    it "returns no findings for clean code" do
      findings = scan_fixture("clean_file.rb", from: "rails-7.2", to: "rails-8.0")
      expect(findings).to be_empty
    end
  end
end
