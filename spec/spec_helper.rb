# frozen_string_literal: true

require "upgrade_radar"

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.order = :random
end

FIXTURES_PATH = File.expand_path("fixtures", __dir__)

def fixture_path(name)
  File.join(FIXTURES_PATH, name)
end

def parse_fixture(name)
  Prism.parse_file(fixture_path(name))
end

def find_call_nodes(code)
  result = Prism.parse(code)
  collector = CallNodeCollector.new
  collector.visit(result.value)
  collector.calls
end

class CallNodeCollector < Prism::Visitor
  attr_reader :calls

  def initialize
    super
    @calls = []
  end

  def visit_call_node(node)
    @calls << node
    super
  end
end
