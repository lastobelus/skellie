require "skellie/version"
require "yaml"
require "active_support/core_ext/hash"
require "awesome_print"

module Skellie
  class Error < StandardError; end

  DEFAULTS = {
    log_level: "verbose",
    models: {
      type_aliases: {
        integer: %W[i int],
        decimal: %w[dec],
        float: %w[f],
        boolean: %w[boo bool],
        binary: [],
        string: %w[s str],
        text: %w[t tx txt],
        date: %w[d],
        time: [],
        datetime: %w[dt],
        references: %w[ref refs],
      },
    },
  }

  @valid_config_keys = DEFAULTS.keys

  # Configure through hash
  def self.configure(opts = {})
    case opts
    when Hash
      opts
    when String, Pathname
      opts = YAML.load(IO.read(opts)).deep_symbolize_keys
    end
    @config = DEFAULTS.deep_merge(opts)
    validate_config
  end

  def self.config
    @config ||= DEFAULTS
  end

  def self.validate_config
    all_type_aliases = @config[:models][:type_aliases].to_a.flatten.map(&:to_sym)
    if all_type_aliases.length > all_type_aliases.uniq.length
      raise Error, "duplicate type_aliases: #{find_duplicates(all_type_aliases).join(", ")}"
    end
    @config
  end

  def self.find_duplicates(word_array)
    word_array.group_by { |e| e }.select { |k, v| k if v.size > 1 }.map(&:first)
  end
end
