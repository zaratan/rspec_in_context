# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "rspec_in_context/version"

Gem::Specification.new do |spec|
  spec.name          = "rspec_in_context"
  spec.version       = RspecInContext::VERSION
  spec.authors       = ["Denis <Zaratan> Pasin"]
  spec.email         = ["denis@pasin.fr"]

  spec.summary       = 'This gem is here to help DRYing your tests cases by giving a better "shared_examples".'
  spec.homepage      = "https://github.com/denispasin/rspec_in_context"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         =
    Dir.chdir(File.expand_path(__dir__)) do
      `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
    end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.required_ruby_version = '>= 2.5.8'
  spec.license = 'MIT'

  spec.add_dependency "activesupport", "> 2.0"
  spec.add_dependency "rspec", "> 3.0"

  spec.add_development_dependency "bundler", "~> 2.1"
  spec.add_development_dependency "bundler-audit", "> 0.6.0"
  spec.add_development_dependency "codacy-coverage", '~> 2.1.0'
  spec.add_development_dependency "faker", "> 1.8"
  spec.add_development_dependency "guard-rspec", "> 4.7"
  spec.add_development_dependency "overcommit", '> 0.46'
  spec.add_development_dependency "rake", "~> 12.0"
  spec.add_development_dependency "rspec_junit_formatter", "~> 0.4.1"
  spec.add_development_dependency "rubocop", "> 0.58"
  spec.add_development_dependency "rubocop-performance"
  spec.add_development_dependency "simplecov", "> 0.16"
  spec.add_development_dependency "solargraph"
  spec.add_development_dependency "yard"
end
