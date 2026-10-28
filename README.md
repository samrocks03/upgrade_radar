# Upgrade Radar

**Know your Ruby/Rails upgrade cost before you start.**

Upgrade Radar is a static analysis gem that scans your codebase for deprecations and breaking changes between Ruby/Rails versions. Run one command and get a full report — what will break, where, why, and how long it will take to fix — before you touch the version number.

```
$ upgrade_radar scan --from rails-7.2 --to rails-8.0

Upgrade Radar v0.1.0
Scanning for: rails-7.2 → rails-8.0
Files scanned: 247

app/models/lead.rb
  [BREAKS] Line 4: Positional hash argument to `enum` is deprecated in Rails 7.2 and removed in 8.0.
    Source: enum status: { draft: 0, published: 1, archived: 2 }
    Fix: enum :status, { active: 0, inactive: 1 }
    Docs: https://guides.rubyonrails.org/upgrading_ruby_on_rails.html#enumerations

app/models/profile.rb
  [BREAKS] Line 5: `serialize` requires an explicit `coder:` keyword argument in Rails 7.1+.
    Source: serialize :tags, Array
    Fix: serialize :attr, coder: JSON

app/controllers/api_controller.rb
  [BREAKS] Line 17: `params.require(:x).permit(...)` is deprecated in Rails 8.0.
    Source: params.require(:user).permit(:name, :email)
    Fix: params.expect(user: [:name, :email])

============================================================
UPGRADE SUMMARY
============================================================
  Total findings:  14
  Breaking:        11
  Warnings:        3
  Files affected:  8
  Estimated effort: ~2.5 hours (small)

  Scan completed in 0.03s
```

---

## Table of Contents

- [The Problem](#the-problem)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Commands](#commands)
- [Output Formats](#output-formats)
- [Configuration](#configuration)
- [Runtime Mode](#runtime-mode)
- [Built-in Rules](#built-in-rules)
- [Custom Rules](#custom-rules)
- [Architecture](#architecture)
- [Comparison with Existing Tools](#comparison-with-existing-tools)
- [Development](#development)
- [License](#license)

---

## The Problem

Upgrading Ruby (say 3.3 → 3.4) or Rails (7.2 → 8.0) usually goes like this:

1. Bump the version
2. Run tests
3. Watch things break
4. Dig through changelogs to figure out why
5. Repeat for weeks

For a big app, you can't easily estimate the effort beforehand. You don't know if it's a 2-hour job or a 2-week project until you're in the middle of it.

**Upgrade Radar solves this.** Before upgrading, you run one command and get a complete report — every breaking change and deprecation in your codebase, with the exact file, line, fix, and documentation link. You know the cost before you start.

---

## Installation

### As a Gemfile dependency (recommended)

```ruby
# Gemfile
gem "upgrade_radar", group: :development
```

Then run:

```bash
bundle install
```

### Standalone installation

```bash
gem install upgrade_radar
```

### Requirements

- **Ruby >= 3.2.0** (uses the [Prism](https://github.com/ruby/prism) parser, Ruby's official AST parser since 3.3)
- No Rails dependency for static analysis — works on any Ruby project

---

## Quick Start

### Scan for Rails upgrade issues

```bash
upgrade_radar scan --from rails-7.2 --to rails-8.0
```

### Scan for Ruby upgrade issues

```bash
upgrade_radar scan --from ruby-3.3 --to ruby-3.4
```

### Get a JSON report for CI

```bash
upgrade_radar scan --from rails-7.2 --to rails-8.0 --format json --output report.json
```

The exit code is **1** when breaking changes are found, **0** otherwise — so you can gate CI on it.

---

## Commands

### `upgrade_radar scan`

The main command. Scans your codebase and reports findings.

```
Usage:
  upgrade_radar scan --from FROM --to TO

Options:
  --from       Source version (e.g., rails-7.2, ruby-3.3)         [required]
  --to         Target version (e.g., rails-8.0, ruby-3.4)         [required]
  --path       Path to scan (default: current directory)
  --format     Output format: text, json, html (default: text)
  --output     Write report to file instead of stdout
  --exclude    Glob patterns to exclude (e.g., vendor/** tmp/**)
  --config     Path to config file
```

**Examples:**

```bash
# Scan only the app directory
upgrade_radar scan --from rails-7.2 --to rails-8.0 --path app/

# Exclude vendor and generated files
upgrade_radar scan --from rails-7.2 --to rails-8.0 --exclude vendor/** db/schema.rb

# Generate an HTML report
upgrade_radar scan --from rails-7.2 --to rails-8.0 --format html --output upgrade_report.html
```

### `upgrade_radar rules`

List all rules that apply for a version range, without scanning any files.

```bash
upgrade_radar rules --from rails-7.2 --to rails-8.0
upgrade_radar rules --from ruby-3.2 --to ruby-3.4 --format json
```

### `upgrade_radar version`

```bash
upgrade_radar version
# upgrade_radar 0.1.0
```

---

## Output Formats

### Text (default)

Colorized terminal output with `[BREAKS]` and `[WARN]` badges, grouped by file. Includes an effort summary at the bottom.

### JSON

Structured output for CI pipelines and tooling:

```json
{
  "metadata": {
    "upgrade_radar_version": "0.1.0",
    "from": "rails-7.2",
    "to": "rails-8.0",
    "scanned_at": "2026-10-27T15:45:28+0530",
    "scan_duration_seconds": 0.012,
    "files_scanned": 247
  },
  "summary": {
    "total_findings": 14,
    "breaking": 11,
    "warnings": 3,
    "files_affected": 8,
    "total_effort_minutes": 150,
    "total_effort_human": "~2.5 hours",
    "effort_level": "small"
  },
  "findings": [
    {
      "id": "rails-7.2-enum-keyword-args",
      "severity": "breaking",
      "file": "app/models/lead.rb",
      "line": 4,
      "message": "Positional hash argument to `enum` is deprecated...",
      "replacement": "enum :status, { active: 0, inactive: 1 }",
      "docs": "https://guides.rubyonrails.org/...",
      "effort_minutes": 5
    }
  ]
}
```

### HTML

A standalone, self-contained HTML report with dark mode support, severity badges, and effort summary cards. Suitable for sharing with the team.

```bash
upgrade_radar scan --from rails-7.2 --to rails-8.0 --format html --output report.html
```

---

## Configuration

Create `.upgrade_radar.yml` in your project root to set defaults:

```yaml
# .upgrade_radar.yml
exclude:
  - vendor/**
  - tmp/**
  - log/**
  - db/schema.rb
  - node_modules/**
custom_rules_path: ./my_rules/
```

The following paths are excluded by default: `vendor/**`, `node_modules/**`, `tmp/**`, `log/**`.

---

## Runtime Mode

Some deprecations only surface at runtime — for example, Rails deprecation warnings emitted during test execution. Upgrade Radar provides optional hooks to capture these.

### RSpec Integration

```ruby
# spec/spec_helper.rb
require "upgrade_radar/runtime/middleware"

UpgradeRadar::Runtime::Middleware.setup_for_rspec
```

### Minitest Integration

```ruby
# test/test_helper.rb
require "upgrade_radar/runtime/middleware"

collector = UpgradeRadar::Runtime::Middleware.setup_for_minitest
```

### What It Captures

- **Rails deprecations** via `ActiveSupport::Deprecation` (Rails 7.1+ deprecators API and legacy API)
- **Ruby deprecations** via `Warning[:deprecated]` (Ruby 3.0+)

Captured warnings are printed after the test suite with file/line information.

---

## Built-in Rules

Upgrade Radar ships with **19 rules** covering the most impactful breaking changes in recent Rails and Ruby versions.

### Rails Rules (9)

| Rule ID | What It Detects | Introduced | Breaks |
|---------|-----------------|------------|--------|
| `rails-7.1-serialize-coder` | `serialize` without explicit `coder:` keyword | 7.1 | 8.0 |
| `rails-7.2-enum-keyword-args` | Old-style `enum status: {}` hash syntax | 7.2 | 8.0 |
| `rails-7.2-secrets-removed` | `Rails.application.secrets` usage | 7.2 | 7.2 |
| `rails-7.2-alias-attribute` | `alias_attribute` bypassing custom accessors | 7.2 | 7.2 |
| `rails-8.0-connection-pool` | `connection_pool.connection` (removed) | 8.0 | 8.0 |
| `rails-8.0-params-expect` | `params.require(:x).permit(...)` chain | 8.0 | 8.0 |
| `rails-8.0-proxy-object` | `ActiveSupport::ProxyObject` (removed) | 8.0 | 8.0 |
| `rails-8.0-form-with-nil` | `form_with model: nil` (invalid) | 8.0 | 8.0 |
| `rails-8.0-read-encrypted-secrets` | `config.read_encrypted_secrets` (removed) | 8.0 | 8.0 |

### Ruby Rules (10)

| Rule ID | What It Detects | Introduced | Breaks |
|---------|-----------------|------------|--------|
| `ruby-3.3-it-block-param` | Bare `it` in parameterless blocks | 3.3 | 3.4 |
| `ruby-3.3-default-gems-bundled` | `require 'csv'` etc. without Gemfile entry | 3.3 | 3.4 |
| `ruby-3.3-lambda-proc` | `lambda(&non_lambda_proc)` | 3.3 | 3.3 |
| `ruby-3.3-time-new-string` | `Time.new("2024-01-15")` partial strings | 3.3 | 3.3 |
| `ruby-3.3-io-pipe` | `IO.read("\| cmd")` pipe prefix | 3.3 | 3.3 |
| `ruby-3.4-kwargs-index` | `obj[1, key: val]` kwargs in `[]` | 3.4 | 3.4 |
| `ruby-3.4-range-size` | `Range#size` on non-iterable ranges (low confidence) | 3.4 | 3.4 |
| `ruby-3.4-socket-resolution-error` | `rescue SocketError` missing new subclass | 3.4 | 3.4 |
| `ruby-3.4-chilled-string` | `"literal".gsub!` string mutation | 3.4 | 3.4 |
| `ruby-3.4-hash-inspect` | `Hash#inspect` format change (low confidence) | 3.4 | 3.4 |

### Severity Levels

- **BREAKING** — Code will fail (raise an error, change behavior silently, or be removed) in the target version
- **WARNING** — Code is deprecated and emits warnings; will break in a future version

Severity is computed dynamically based on the `--to` version. A rule that is a warning in 7.2 becomes breaking in 8.0.

Rules marked `confidence: low` (`ruby-3.4-range-size`, `ruby-3.4-hash-inspect`) can't determine the receiver type statically, so they are always reported as **WARNING** and never cause a non-zero exit code on their own.

---

## Custom Rules

You can author your own rules as YAML files. Point Upgrade Radar to them via config:

```yaml
# .upgrade_radar.yml
custom_rules_path: ./my_rules/
```

### Rule Schema

```yaml
# my_rules/custom.yml
- id: my-app-deprecated-helper       # Unique rule identifier
  framework: rails                    # "rails" or "ruby"
  introduced_in: "8.0"               # Version where this was deprecated/changed
  breaking_in: "8.0"                 # Version where this breaks
  pattern:
    type: method_call                 # Pattern type (see below)
    name: legacy_helper               # Method name to match
    receiver: null                    # null = implicit self
    conditions: []                    # Additional conditions
  message: >                         # What to tell the developer
    `legacy_helper` is removed. Use `modern_helper` instead.
  replacement: "modern_helper"        # Suggested fix
  docs: "https://wiki.example.com/upgrade"
  effort_minutes: 5                  # Estimated fix time per occurrence
  confidence: high                   # Optional; "low" = always reported as a warning
```

### Pattern Types

| Type | Matches | Use For |
|------|---------|---------|
| `method_call` | `Prism::CallNode` | Method invocations, chained calls |
| `constant_reference` | `Prism::ConstantPathNode` | Class/module references |
| `block_parameter` | `ItLocalVariableReadNode` | Bare `it` in blocks |
| `gemfile_dependency` | Gemfile analysis | Missing gem declarations |
| `string_mutation` | Literal string mutations | `"str".gsub!` patterns |

### Available Conditions (for `method_call` type)

| Condition | Example | Description |
|-----------|---------|-------------|
| `no_keyword` | `{no_keyword: coder}` | Keyword arg must NOT be present |
| `has_block_pass` | `{has_block_pass: true}` | Has `&block` argument |
| `first_arg_type` | `{first_arg_type: hash}` | First arg is hash/string/symbol/constant |
| `first_arg_starts_with` | `{first_arg_starts_with: "\|"}` | First string arg starts with prefix |
| `keyword_value` | `{keyword_value: {key: model, value: nil}}` | Keyword has specific value |
| `has_keywords` | `{has_keywords: true}` | Has any keyword arguments |
| `min_positional_args` | `{min_positional_args: 1}` | Minimum positional arg count |

---

## Architecture

### How It Works

```
┌──────────────┐     ┌───────────────┐     ┌───────────────┐
│  YAML Rules  │────▶│ Rule Registry │────▶│ Active Rules  │
│  (19 rules)  │     │ (load+filter) │     │ (for version) │
└──────────────┘     └───────────────┘     └───────┬───────┘
                                                   │
┌──────────────┐     ┌───────────────┐     ┌───────▼───────┐
│  Ruby Files  │────▶│ Prism Parser  │────▶│ AuditVisitor  │
│  (FileFinder)│     │ (AST per file)│     │ (1 walk/file) │
└──────────────┘     └───────────────┘     └───────┬───────┘
                                                   │
                                           ┌───────▼───────┐
                                           │   Matchers    │
                                           │ (5 types)     │
                                           └───────┬───────┘
                                                   │
                     ┌───────────────┐     ┌───────▼───────┐
                     │  Formatters   │◀────│   Findings    │
                     │ (text/json/   │     │   + Result    │
                     │  html)        │     └───────────────┘
                     └───────────────┘
```

### Key Design Decisions

1. **Single AuditVisitor (Commissioner pattern)** — One `Prism::Visitor` subclass walks each file's AST once and dispatches to all relevant matchers. Same pattern RuboCop uses. This is O(nodes x relevant_rules), not O(nodes x all_rules).

2. **YAML rules with typed matchers** — Rules are defined in accessible YAML. Each `pattern.type` maps to a Ruby matcher class. You don't need Ruby knowledge to author a rule.

3. **Dynamic severity** — A rule's severity depends on the target version. `serialize` without `coder:` is a warning in Rails 7.2 but breaking in 8.0.

4. **Version resolution via `Gem::Version`** — Built into Ruby, handles comparison correctly, no external dependency.

### Module Structure

```
UpgradeRadar
├── CLI                       # Thor CLI (scan, rules, version)
├── Scanner                   # Orchestrator
├── FileFinder                # File discovery with excludes
├── Rule / RuleRegistry       # YAML rule loading + version filtering
├── VersionRange              # "rails-7.2" parsing
├── AuditVisitor              # Prism::Visitor subclass
├── Matchers/
│   ├── MethodCallMatcher     # 14 of 19 rules
│   ├── ConstantReferenceMatcher
│   ├── BlockParameterMatcher
│   ├── GemfileMatcher
│   └── StringMutationMatcher
├── Finding / Result          # Data model
├── EffortEstimator           # Time estimation
├── Formatters/
│   ├── TextFormatter         # Colorized CLI
│   ├── JsonFormatter         # CI-friendly
│   └── HtmlFormatter         # Shareable report
└── Runtime/
    ├── Collector             # Deduplicating warning collector
    ├── RailsHook             # ActiveSupport::Deprecation hook
    ├── RubyWarningHook       # Warning[:deprecated] hook
    └── Middleware             # RSpec/Minitest integration
```

---

## Comparison with Existing Tools

| Tool | Static Analysis | Runtime Capture | Version-to-Version Report | Effort Estimate |
|------|:-:|:-:|:-:|:-:|
| **Upgrade Radar** | Yes | Yes | Yes | Yes |
| RuboCop + rubocop-rails | Partial (scattered cops) | No | No | No |
| next_rails (FastRuby.io) | No | Yes | No | No |
| `rails app:update` | No (config files only) | No | No | No |
| Deprecation Toolkit (Shopify) | No | Yes | No | No |

**The gap Upgrade Radar fills:** a single version-to-version report that combines static and runtime findings, tells you what will break before you upgrade, and estimates the effort so you can plan.

---

## CI Integration

### GitHub Actions

```yaml
name: Upgrade Readiness Check

on:
  schedule:
    - cron: '0 9 * * 1'  # Weekly on Monday
  workflow_dispatch:

jobs:
  upgrade-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.3'
      - run: gem install upgrade_radar
      - name: Check Rails upgrade readiness
        run: |
          upgrade_radar scan \
            --from rails-7.2 --to rails-8.0 \
            --format json --output upgrade-report.json
      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: upgrade-report
          path: upgrade-report.json
```

### Exit Codes

| Code | Meaning |
|------|---------|
| `0` | No breaking changes found (warnings only, or clean) |
| `1` | Breaking changes found |
| `2` | Invalid arguments or configuration error |

---

## Development

```bash
git clone https://github.com/samrocks03/upgrade_radar.git
cd upgrade_radar
bundle install
bundle exec rspec        # Run tests (78 specs)
bundle exec rake         # Run tests (default task)
```

### Running Against Your Own App

```bash
cd /path/to/your/rails/app
upgrade_radar scan --from rails-7.2 --to rails-8.0
```

### Adding New Rules

1. Create or edit a YAML file in `rules/rails/` or `rules/ruby/`
2. Follow the schema documented in [Custom Rules](#custom-rules)
3. Add a fixture file in `spec/fixtures/` with the pattern
4. Add a test in `spec/audit_visitor_spec.rb`
5. Run `bundle exec rspec`

---

## License

MIT License. See [LICENSE.txt](LICENSE.txt).
