# frozen_string_literal: true

RSpec.describe UpgradeRadar::Matchers::MethodCallMatcher do
  def match_call(code, pattern)
    calls = find_call_nodes(code)
    matcher = described_class.new(pattern)
    calls.select { |c| matcher.match?(c) }
  end

  describe "enum keyword args detection" do
    let(:pattern) do
      { "type" => "method_call", "name" => "enum", "receiver" => nil,
        "conditions" => [{ "first_arg_type" => "hash" }] }
    end

    it "matches old-style enum" do
      matches = match_call("enum status: { active: 0, inactive: 1 }", pattern)
      expect(matches.size).to eq(1)
    end

    it "does not match new-style enum" do
      matches = match_call("enum :status, { active: 0, inactive: 1 }", pattern)
      expect(matches).to be_empty
    end
  end

  describe "serialize without coder detection" do
    let(:pattern) do
      { "type" => "method_call", "name" => "serialize", "receiver" => nil,
        "conditions" => [{ "no_keyword" => "coder" }] }
    end

    it "matches serialize without coder keyword" do
      matches = match_call("serialize :preferences", pattern)
      expect(matches.size).to eq(1)
    end

    it "matches serialize with class arg but no coder" do
      matches = match_call("serialize :tags, Array", pattern)
      expect(matches.size).to eq(1)
    end

    it "does not match serialize with coder keyword" do
      matches = match_call("serialize :metadata, coder: JSON", pattern)
      expect(matches).to be_empty
    end
  end

  describe "params.require.permit chain detection" do
    let(:pattern) do
      { "type" => "method_call", "name" => "permit", "receiver_method" => "require",
        "conditions" => [] }
    end

    it "matches params.require(:user).permit(:name)" do
      matches = match_call("params.require(:user).permit(:name, :email)", pattern)
      expect(matches.size).to eq(1)
    end

    it "does not match standalone permit" do
      matches = match_call("params.permit(:name)", pattern)
      expect(matches).to be_empty
    end
  end

  describe "connection_pool.connection detection" do
    let(:pattern) do
      { "type" => "method_call", "name" => "connection",
        "receiver_chain" => "**.connection_pool", "conditions" => [] }
    end

    it "matches connection_pool.connection" do
      matches = match_call("ActiveRecord::Base.connection_pool.connection", pattern)
      expect(matches.size).to eq(1)
    end
  end

  describe "secrets detection" do
    let(:pattern) do
      { "type" => "method_call", "name" => "secrets",
        "receiver_chain" => "Rails.application", "conditions" => [] }
    end

    it "matches Rails.application.secrets" do
      matches = match_call("Rails.application.secrets.api_key", pattern)
      expect(matches.size).to eq(1)
    end
  end

  describe "lambda with block pass detection" do
    let(:pattern) do
      { "type" => "method_call", "name" => "lambda", "receiver" => nil,
        "conditions" => [{ "has_block_pass" => true }] }
    end

    it "matches lambda(&handler)" do
      matches = match_call("lambda(&handler)", pattern)
      expect(matches.size).to eq(1)
    end

    it "does not match lambda with block" do
      matches = match_call("lambda { |x| x }", pattern)
      expect(matches).to be_empty
    end
  end

  describe "IO pipe detection" do
    let(:pattern) do
      { "type" => "method_call", "name" => %w[read open], "receiver" => "IO",
        "conditions" => [{ "first_arg_starts_with" => "|" }] }
    end

    it "matches IO.read with pipe prefix" do
      matches = match_call('IO.read("| hostname")', pattern)
      expect(matches.size).to eq(1)
    end

    it "does not match IO.read with file path" do
      matches = match_call('IO.read("/proc/uptime")', pattern)
      expect(matches).to be_empty
    end
  end

  describe "Time.new with string detection" do
    let(:pattern) do
      { "type" => "method_call", "name" => "new", "receiver" => "Time",
        "conditions" => [{ "first_arg_type" => "string" }] }
    end

    it "matches Time.new with string arg" do
      matches = match_call('Time.new("2024-01-15")', pattern)
      expect(matches.size).to eq(1)
    end

    it "does not match Time.new with integer args" do
      matches = match_call("Time.new(2024, 1, 15)", pattern)
      expect(matches).to be_empty
    end
  end

  describe "form_with model: nil detection" do
    let(:pattern) do
      { "type" => "method_call", "name" => "form_with", "receiver" => nil,
        "conditions" => [{ "keyword_value" => { "key" => "model", "value" => "nil" } }] }
    end

    it "matches form_with model: nil" do
      matches = match_call('form_with model: nil, url: "/search"', pattern)
      expect(matches.size).to eq(1)
    end

    it "does not match form_with with a model" do
      matches = match_call("form_with model: @user", pattern)
      expect(matches).to be_empty
    end
  end
end
