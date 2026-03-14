# frozen_string_literal: true

require 'legion/extensions/cognitive_contagion/helpers/constants'
require 'legion/extensions/cognitive_contagion/helpers/meme'
require 'legion/extensions/cognitive_contagion/helpers/contagion_engine'
require 'legion/extensions/cognitive_contagion/runners/cognitive_contagion'

module Legion
  module Extensions
    module CognitiveContagion
      class Client
        include Runners::CognitiveContagion

        def initialize(**)
          @engine = Helpers::ContagionEngine.new
        end

        private

        attr_reader :engine
      end
    end
  end
end
