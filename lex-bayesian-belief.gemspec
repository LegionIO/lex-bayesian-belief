# frozen_string_literal: true

require_relative 'lib/legion/extensions/bayesian_belief/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-bayesian-belief'
  spec.version       = Legion::Extensions::BayesianBelief::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matthewdiverson@gmail.com']

  spec.summary       = 'LEX Bayesian Belief'
  spec.description   = 'Bayesian belief updating engine (prior + evidence = posterior) for brain-modeled agentic AI'
  spec.homepage      = 'https://github.com/LegionIO/lex-bayesian-belief'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['homepage_uri']        = spec.homepage
  spec.metadata['source_code_uri']     = 'https://github.com/LegionIO/lex-bayesian-belief'
  spec.metadata['documentation_uri']   = 'https://github.com/LegionIO/lex-bayesian-belief'
  spec.metadata['changelog_uri']       = 'https://github.com/LegionIO/lex-bayesian-belief'
  spec.metadata['bug_tracker_uri']     = 'https://github.com/LegionIO/lex-bayesian-belief/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir.glob('{lib,spec}/**/*') + %w[lex-bayesian-belief.gemspec Gemfile]
  end
  spec.require_paths = ['lib']
end
