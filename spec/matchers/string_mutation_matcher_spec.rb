# frozen_string_literal: true

RSpec.describe UpgradeRadar::Matchers::StringMutationMatcher do
  let(:pattern) { { "type" => "string_mutation", "detect_literal_mutation" => true } }
  let(:matcher) { described_class.new(pattern) }

  it "matches string literal << mutation" do
    calls = find_call_nodes('"hello" << " world"')
    matches = calls.select { |c| matcher.match?(c) }
    expect(matches.size).to eq(1)
  end

  it "matches string literal gsub! mutation" do
    calls = find_call_nodes('"test".gsub!("t", "T")')
    matches = calls.select { |c| matcher.match?(c) }
    expect(matches.size).to eq(1)
  end

  it "does not match mutation on variable" do
    calls = find_call_nodes('str = "hello"; str << " world"')
    append_calls = calls.select { |c| c.name == :<< }
    matches = append_calls.select { |c| matcher.match?(c) }
    expect(matches).to be_empty
  end
end
