# Skellie

Skellie is a tool for sketching a rails app in yaml. Essentially, it is a productive, iterative way to run a lot of rails generators to sketch the initial implementation of your app (or initial implementation of a new feature) with no penalty for changing your mind along the way.

It is git-aware and designed to be part of a Pull Request workflow.

## Long Term Goals of Skellie

The name comes from the "walking skeleton" concept, but whereas the standard idea of a walking skeleton is a deployable, minimalistic, end-to-end implementation of an app skellie focuses on the next level of detail: initial domain modelling and bare bones flows through the app using that model.

### Zero Magic
Skellie does not add any framework or abstract code to your rails app (no magic!) but operates by using git and rails generators to add code to your app in a controlled way. Using skellie in an app always remains optional & orthogonal to other development practices. 

### Idempotency

A significant long term goal is for Skellie to always remain idempotent:

1. if you run a skellie.yml file more than once on your app from the same starting point, the result should be the same.
2. if you make a change to a skellie.yml file and run it again, the difference in result should be entirely described by the difference between the two versions of the skellie.yml file.
3. Running a skellie.yml file should not change or delete code you have written outside of using skellie unless the skellie.yml file directly states it should (skellie has syntax for renaming/deleting exiisting models/attributes etc.)

### FUDless

Skellie should minimize or eliminate all FUD associated with using it. A Skellie user should always feel confident that they can write & run a skellie.yml file in any rails app and:

1. Be confident that skellie won't delete/alter existing code unless directed to
2. Be confident that skellie won't affect development database until it is directed to merge its  changes
3. Be confident that a skellie run is trivially revertible with a single command
4. Be able to start writing skellie.yml and refer to existing rails models, attributes, etc. without having to specify them in the skellie.yml file.

To accopmlish this 

1. It should use it's own copy of the database, so that running it does not render master or other branches broken at the data level
2. When merging it should make a dump of the development db first
3. It should refuse to run on master (and optionally on any branch other than a designated one)
4. It should always start with a hard reset to master:HEAD unless otherwise desired
5. It should commit each change/generator-run it does atomically, optionally squashing them at the end of a session.
6. By committing each change atomically, it can automatically bisect when a session results in failing tests to find the individual change that causes the failure.
7. It runs in the context of a loaded version of your app so you can refer to existing objects/attributes


## Installation

Add this line to your rails application's Gemfile in the development section:

```ruby
gem 'skellie'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install skellie
```

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/lastobelus/skellie.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
