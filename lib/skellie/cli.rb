require 'thor'

module Skellie
  class CLI < Thor
    package_name "skellie"
    map "gen" => :generate

    desc "generate", "generate rails files from a skellie.yml file"
    def generate
      puts "generating..."
    end
    default_task :generate
  end
end