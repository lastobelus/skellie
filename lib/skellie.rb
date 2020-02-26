require "skellie/version"
require "yaml"
require "active_support/core_ext/hash"
require "awesome_print"

module Skellie
  class Error < StandardError; end

  @config = {
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

  @valid_config_keys = @config.keys

  # Configure through hash
  def self.configure(opts = {})
    case opts
    when Hash
      opts
    when String, Pathname
      opts = YAML.load(IO.read(opts)).deep_symbolize_keys
    end
    @config = @config.deep_merge(opts)
  end

  def self.config
    @config
  end
end
