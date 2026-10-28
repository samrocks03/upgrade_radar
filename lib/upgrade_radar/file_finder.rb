# frozen_string_literal: true

module UpgradeRadar
  class FileFinder
    RUBY_EXTENSIONS = %w[.rb .rake .gemspec].freeze
    SPECIAL_FILES = %w[Gemfile Rakefile].freeze
    DEFAULT_EXCLUDES = %w[vendor/** node_modules/** tmp/** log/**].freeze

    def initialize(base_path, exclude_patterns: [])
      @base_path = File.expand_path(base_path)
      @exclude_patterns = DEFAULT_EXCLUDES + exclude_patterns
    end

    def ruby_files
      pattern = File.join(@base_path, "**", "*")
      Dir.glob(pattern).select { |f| ruby_file?(f) && !excluded?(f) }.sort
    end

    def gemfile_path
      path = File.join(@base_path, "Gemfile")
      File.exist?(path) ? path : nil
    end

    private

    def ruby_file?(path)
      return false unless File.file?(path)

      ext = File.extname(path)
      return true if RUBY_EXTENSIONS.include?(ext)

      SPECIAL_FILES.include?(File.basename(path))
    end

    def excluded?(path)
      relative = path.sub("#{@base_path}/", "")
      @exclude_patterns.any? { |pattern| File.fnmatch?(pattern, relative, File::FNM_PATHNAME) }
    end
  end
end
