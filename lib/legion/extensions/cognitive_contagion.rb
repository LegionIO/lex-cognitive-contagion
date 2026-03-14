# frozen_string_literal: true

require 'legion/extensions/cognitive_contagion/version'
require 'legion/extensions/cognitive_contagion/helpers/constants'
require 'legion/extensions/cognitive_contagion/helpers/meme'
require 'legion/extensions/cognitive_contagion/helpers/contagion_engine'
require 'legion/extensions/cognitive_contagion/runners/cognitive_contagion'
require 'legion/extensions/cognitive_contagion/client'

module Legion
  module Extensions
    module CognitiveContagion
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
    end
  end
end
