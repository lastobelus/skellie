require "skellie/version"
require "yaml"

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
    opts.each { |k, v| @config[k.to_sym] = v if @valid_config_keys.include? k.to_sym }
  end

  # Configure through yaml file
  def self.configure_with(path_to_yaml_file)
    config = YAML.load(IO.read(path_to_yaml_file))
    configure(config)
  end

  def self.config
    @config
  end
end
