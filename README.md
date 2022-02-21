# OffenseToCorrector

> **WARNING**: This is an experimental alpha used as a proof-of-concept, and will
> require some work to be ready for full-time use in the field.

Takes a RuboCop of Ruby offense like so:

```ruby
code = <<~RUBY
  update_attributes_book.update_attributes(author: "Alice")
                         ^^^^^^^^^^^^^^^^^ Use `update` instead of `update_attributes`.
RUBY
```

...and turns it into a skeleton for a RuboCop corrector:

```ruby
puts OffenseToCorrector.node_offense_data(CODE)

{
  offending_node: %(#<struct OffenseToCorrector::AtomNode
    source="update_attributes",
    range=23..40,
    parent=s(:send,
      s(:send, nil, :update_attributes_book), :update_attributes,
      s(:hash,
        s(:pair,
          s(:sym, :author),
          s(:str, "Alice"))))>),
  offending_node_matcher: "(send ... :update_attributes ...)"
}

puts OffenseToCorrector.offense_to_cop(code)

# Generated content
module RuboCop
  module Cop
    module Lint
      class TODO < Cop
        MSG = "Use `update` instead of `update_attributes`."

        def_node_matcher :matches?, <<~PATTERN
          (send ... :update_attributes ...)
        PATTERN

        def on_send(node)
          return false unless matches?(node)

          add_offense(node,
            message: MSG,
            location: :selector,
            severity: :warning
          )
        end

        # def autocorrect(node)
        #   lambda do |corrector|
        #     corrector.replace(
        #       node.loc.selector,
        #       "<NEW_CODE_HERE>"
        #     )
        #   end
        # end
      end
    end
  end
end
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'offense_to_corrector'
```

And then execute:

```
$ bundle install
```

Or install it yourself as:

```
$ gem install offense_to_corrector
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/baweaver/offense_to_corrector. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/baweaver/offense_to_corrector/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the OffenseToCorrector project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/baweaver/offense_to_corrector/blob/main/CODE_OF_CONDUCT.md).
