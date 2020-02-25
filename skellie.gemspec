require_relative "lib/skellie/version"

Gem::Specification.new do |spec|
  spec.name = "skellie"
  spec.version = Skellie::VERSION
  spec.authors = ["Michael Johnston"]
  spec.email = ["lastobelus@mac.com"]

  spec.summary = "Skellie is a tool for sketching a rails app in yaml"
  spec.description = 'Skellie is a tool for sketching a rails app in yaml. Essentially, it is a productive, iterative way to run a lot of rails generators to sketch the initial implementation of your app (or initial implementation of a new feature) with no penalty for changing your mind along the way. It is git-aware and designed to be part of a Pull Request workflow. The name comes from the "walking skeleton" concept, but whereas the standard idea of a walking skeleton is a deployable, minimalistic, end-to-end implementation of an app skellie focuses on the next level of detail: initial domain modelling and bare bones flows through the app using that model. It is designed to be Zero Magic and does not add any framework or abstract code to your rails app; but operates by using git and rails generators to add code to your app in a controlled way.'
  spec.homepage = "https://github.com/lastobelus/skellie"
  spec.license = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/master/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"] = "#{spec.homepage}/issues"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path("..", __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport"

  spec.add_development_dependency "standard"
  spec.add_development_dependency "reek"
  spec.add_development_dependency "rspec"
end
