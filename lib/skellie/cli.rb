require 'thor'
require 'yaml'
require "active_support/core_ext/hash"
require "awesome_print"

module Skellie
  class CLI < Thor
    package_name "skellie"
    map "gen" => :generate

    desc "generate", "generate rails files from a skellie.yml file"
    method_option :file, aliases: "-f", default: "skellie.yml"
    def generate
      skellie = load_file(options[:file])
      puts "generating..."
      ap skellie
    end
    default_task :generate

    private
    def load_file(path)
      puts "load_file #{path}"
      YAML.load(IO.read(path)).deep_symbolize_keys
    end
  end
end