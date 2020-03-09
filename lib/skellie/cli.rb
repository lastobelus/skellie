require "thor"
require "yaml"
require "active_support/core_ext/hash"
require "awesome_print"
require "skellie/sketch/app"

module Skellie
  class CLI < Thor
    package_name "skellie"
    map "gen" => :generate

    desc "generate", "generate rails files from a skellie.yml file"
    method_option :file, aliases: "-f", default: "skellie.yml"
    def generate
      sketch = Skellie::Sketch::App.new(file: options[:file])
      puts "generating..."
      ap sketch
    end
    default_task :generate

    private
  end
end
