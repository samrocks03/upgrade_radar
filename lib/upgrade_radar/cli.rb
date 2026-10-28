# frozen_string_literal: true

require "thor"

module UpgradeRadar
  class CLI < Thor
    def self.exit_on_failure?
      true
    end

    desc "scan", "Scan codebase for deprecations and breaking changes"
    option :from, required: true, type: :string, desc: "Source version (e.g., rails-7.2, ruby-3.3)"
    option :to, required: true, type: :string, desc: "Target version (e.g., rails-8.0, ruby-3.4)"
    option :path, type: :string, default: ".", desc: "Path to scan"
    option :format, type: :string, default: "text", enum: %w[text json html], desc: "Output format"
    option :output, type: :string, desc: "Output file path (default: stdout)"
    option :exclude, type: :array, default: [], desc: "Glob patterns to exclude"
    option :config, type: :string, desc: "Path to config file"
    def scan
      from, to = VersionRange.parse(options[:from], options[:to])
      config = Configuration.new(options)
      scanner = Scanner.new(from: from, to: to, config: config)
      result = scanner.run

      formatter = Formatters::Base.for(options[:format])
      output = formatter.format(result)

      if options[:output]
        File.write(options[:output], output)
        $stderr.puts "Report written to #{options[:output]}"
      else
        puts output
      end

      exit(result.exit_code)
    rescue ArgumentError => e
      $stderr.puts "Error: #{e.message}"
      exit(2)
    end

    desc "rules", "List available rules for a version range"
    option :from, required: true, type: :string
    option :to, required: true, type: :string
    option :format, type: :string, default: "text", enum: %w[text json]
    def rules
      from, to = VersionRange.parse(options[:from], options[:to])
      registry = RuleRegistry.new.load_builtin_rules
      matching = registry.rules_for(from, to)

      if options[:format] == "json"
        data = matching.map do |r|
          { id: r.id, severity: r.severity_for(to.version), message: r.message, docs: r.docs }
        end
        puts JSON.pretty_generate(data)
      else
        puts "Rules for #{from} → #{to} (#{matching.size} rules):\n\n"
        matching.each do |r|
          severity = r.severity_for(to.version)
          badge = severity == :breaking ? "[BREAKS]" : "[WARN]  "
          puts "  #{badge} #{r.id}"
          puts "    #{r.message}"
          puts ""
        end
      end
    rescue ArgumentError => e
      $stderr.puts "Error: #{e.message}"
      exit(2)
    end

    desc "version", "Print version"
    def version
      puts "upgrade_radar #{UpgradeRadar::VERSION}"
    end

    map %w[-v --version] => :version
  end
end
