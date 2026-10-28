# frozen_string_literal: true

require "open3"
require "rbconfig"

RSpec.describe "UpgradeRadar::Runtime::Middleware" do
  let(:lib_path) { File.expand_path("../../lib", __dir__) }

  # Run in a subprocess: the documented entry point is requiring the
  # middleware on its own, and installing the hooks patches Warning globally.
  it "loads standalone and installs the hooks" do
    script = <<~RUBY
      require "upgrade_radar/runtime/middleware"
      collector = UpgradeRadar::Runtime::Middleware.setup_for_minitest
      Warning.warn("old api\\n", category: :deprecated)
      print collector.size
    RUBY

    stdout, stderr, status = Open3.capture3(RbConfig.ruby, "-I", lib_path, "-e", script)

    expect(status).to be_success, stderr
    expect(stdout).to eq("1")
  end
end
