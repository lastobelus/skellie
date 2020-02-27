source "https://rubygems.org"

# Specify your gem's dependencies in skellie.gemspec
gemspec

gem "rake", "~> 12.0"

group :development do
  gem "guard-rspec", require: false
  gem "guard-bundler", require: false
end

group :development, :test do
  gem "pry", github: 'pry/pry'
end
