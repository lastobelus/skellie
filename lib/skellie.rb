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
        integer: %i[i int],
        decimal: %i[dec],
        float: %i[f],
        boolean: %i[boo bool],
        binary: %i[bi],
        string: %i[s str],
        text: %i[t tx txt],
        date: %i[d],
        time: %i[ti],
        datetime: %i[dt],
        references: %i[ref refs],
      },
      type_modifier_aliases: {
        default_value: %i[defv],
        default_method: %i[defm],
        required: %i[req],
        poly: %i[],
      },
      assoc_modifier_aliases: {
        through: %i[thru],
        as: [],
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
    normalize_config
    validate_config
  end

  def self.config
    @config ||= DEFAULTS
  end

  def self.normalize_config
    symbol_arrays = %w[
      models.type_aliases.*
      models.type_modifier_aliases.*
      models.assoc_modifier_aliases.*
    ]

    symbol_arrays.each do |path|
      target = path.split(".").map(&:to_sym)
      if target.last == :*
        target.pop
        @config.dig(*target).transform_values! { |v| v.map(&:to_sym) }
      else
        @config.dig(*target[0..-2]).store(target.last, @config.dig(*target).to_sym)
      end
    end
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

  def self.model_attribute_type_aliases
    config[:models][:type_aliases]
  end

  def self.all_model_attribute_type_aliases
    model_attribute_type_aliases.to_a.flatten.map(&:to_sym)
  end

  def self.model_type_modifier_aliases
    config[:models][:type_modifier_aliases]
  end

  def self.all_model_type_modifier_aliases
    model_type_modifier_aliases.to_a.flatten.map(&:to_sym)
  end

  def self.model_association_modifier_aliases
    config[:models][:association_modifier_aliases]
  end

  def self.all_model_association_modifier_aliases
    model_association_modifier_aliases.to_a.flatten.map(&:to_sym)
  end
end
