# frozen_string_literal: true

require_relative 'lib/legion/extensions/cognitive_contagion/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-cognitive-contagion'
  spec.version       = Legion::Extensions::CognitiveContagion::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matthewdiverson@gmail.com']

  spec.summary       = 'LEX Cognitive Contagion'
  spec.description   = 'SIR-inspired cognitive/emotional contagion modeling for brain-modeled agentic AI'
  spec.homepage      = 'https://github.com/LegionIO/lex-cognitive-contagion'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['homepage_uri']        = spec.homepage
  spec.metadata['source_code_uri']     = 'https://github.com/LegionIO/lex-cognitive-contagion'
  spec.metadata['documentation_uri']   = 'https://github.com/LegionIO/lex-cognitive-contagion'
  spec.metadata['changelog_uri']       = 'https://github.com/LegionIO/lex-cognitive-contagion'
  spec.metadata['bug_tracker_uri']     = 'https://github.com/LegionIO/lex-cognitive-contagion/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir.glob('{lib,spec}/**/*') + %w[lex-cognitive-contagion.gemspec Gemfile]
  end
  spec.require_paths = ['lib']
  spec.add_development_dependency 'legion-gaia'
end
