# frozen_string_literal: true

module Legion
  module Extensions
    module CognitiveContagion
      module Helpers
        module Constants
          MAX_AGENTS        = 200
          MAX_MEMES         = 500
          DEFAULT_VIRULENCE = 0.3
          DEFAULT_RESISTANCE = 0.5
          TRANSMISSION_RATE = 0.15
          RECOVERY_RATE     = 0.05
          IMMUNITY_BOOST    = 0.1

          VIRULENCE_LABELS = {
            (0.8..)     => :pandemic,
            (0.6...0.8) => :epidemic,
            (0.4...0.6) => :endemic,
            (0.2...0.4) => :sporadic,
            (..0.2)     => :contained
          }.freeze

          STATUS_LABELS    = %i[susceptible exposed infected recovered immune].freeze
          CONTAGION_TYPES  = %i[emotional belief behavioral cognitive].freeze
        end
      end
    end
  end
end
