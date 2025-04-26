# frozen_string_literal: true

# ocl.gemspec
Gem::Specification.new do |spec|
  spec.name          = 'ocl'
  spec.version       = '0.1.0'
  spec.authors       = ['Takeshi Kakeda']
  spec.email         = ['takeshi@giantech.jp']

  spec.summary       = 'A minimal Object Constraint Language (OCL) engine for Ruby.'
  spec.description   = 'Supports invariant, precondition, postcondition, and derived attributes using a Ruby DSL.'
  spec.homepage      = 'https://github.com/yourname/ocl'
  spec.license       = 'MIT'

  spec.files         = Dir['lib/**/*.rb']
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 3.2'
  spec.add_development_dependency 'rspec', '~> 3.12'
end
