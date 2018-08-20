# RspecInContext

This gem is here to help you write better shared_examples in Rspec.

Ever been bothered by the fact that they don't really behave like methods and that you can't pass it a block ? There you go: `rspec_in_context`

**NOTE**: This is an alpha version. For now context are globally scoped.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rspec_in_context'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rspec_in_context

## Usage

### Add this into Rspec

You must require the gem on top of your spec_helper:
```ruby
require 'rspec_in_context'
```

Then include it into Rspec:
```ruby
RSpec.configure do |config|
  [...]
  
  config.include RspecInContext
end
```

### Define a new in_context

You can define in_context block that are reusable almost anywhere.
They completely look like normal Rspec.

##### Inside a Rspec block

```ruby
# A in_context can be named with a symbol or a string
define_context :context_name do
  it 'works' do
    expect(true).to be_truthy
  end
end
```

##### Outside a Rspec block

Outside of a test you have to use `RSpec.define_context`.


### Use the context

Anywhere in your test description, use a `in_context` block to use a predefined in_context. **They don't need to be in the same file.** Example:

```ruby
# A in_context can be named with a symbol or a string
define_context :context_name do
  it 'works' do
    expect(true).to be_truthy
  end
end

[...]
Rspec.describe MyClass do
  in_context :context_name # => will execute the 'it works' test here
end
```

### Things to know

* You can chose exactly where your inside test will be used:
By using `execute_tests` in your define context, the test passed when you *use* the context will be executed here

```ruby
define_context :context_name do
  it 'works' do
    expect(true).to be_truthy
  end
  context "in this context pomme exists" do
    let(:pomme) { "abcd" }
    
    execute_tests
  end
end

[...]

in_context :context_name do
  it 'will be executed at execute_tests place' do
    expect(pomme).to eq("abcd") # => true
  end
end
```

* You can use variable in the in_context definition

```ruby
define_context :context_name do |name|
  it 'works' do
    expect(true).to be_truthy
  end
  context "in this context #{name} exists" do
    let(name) { "abcd" }
    
    execute_tests
  end
end

[...]

in_context :context_name, :poire do
  it 'the right variable will exists' do
    expect(poire).to eq("abcd") # => true
  end
end
```

* In_contexts can be scope inside one another

```ruby
define_context :context_name do |name|
  it 'works' do
    expect(true).to be_truthy
  end
  context "in this context #{name} exists" do
    let(name) { "abcd" }
    
    execute_tests
  end
end

define_context "second in_context" do
  context 'and tree also' do
    let(:tree) { 'abcd' }

    it 'will scope correctly' do
      expect(tree).to eq(poire)
    end
  end
end

[...]

in_context :context_name, :poire do
  it 'the right variable will exists' do
    expect(poire).to eq("abcd") # => true
  end

  in_context "second in_context" # => will work
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/denispasin/rspec_in_context.
