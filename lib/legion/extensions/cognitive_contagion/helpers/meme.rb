# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module CognitiveContagion
      module Helpers
        class Meme
          attr_reader :id, :label, :contagion_type, :virulence,
                      :carriers, :recovered, :immune,
                      :total_transmissions, :created_at

          def initialize(label:, contagion_type: :cognitive, virulence: Constants::DEFAULT_VIRULENCE)
            @id                  = SecureRandom.uuid
            @label               = label
            @contagion_type      = validate_contagion_type(contagion_type)
            @virulence           = virulence.clamp(0.0, 1.0).round(10)
            @carriers            = Set.new
            @recovered           = Set.new
            @immune              = Set.new
            @total_transmissions = 0
            @created_at          = Time.now.utc
          end

          def virulence_label
            Constants::VIRULENCE_LABELS.find { |range, _| range.cover?(@virulence) }&.last || :contained
          end

          def carrier_count
            @carriers.size
          end

          def transmission_rate
            return 0.0 if @carriers.empty?

            (@total_transmissions.to_f / @carriers.size).round(10)
          end

          def infect!(agent_id:)
            return :already_carrier if @carriers.include?(agent_id)
            return :immune          if @immune.include?(agent_id)

            @carriers.add(agent_id)
            @recovered.delete(agent_id)
            @total_transmissions += 1
            :infected
          end

          def recover!(agent_id:)
            return :not_a_carrier unless @carriers.include?(agent_id)

            @carriers.delete(agent_id)
            @recovered.add(agent_id)
            :recovered
          end

          def immunize!(agent_id:)
            @carriers.delete(agent_id)
            @immune.add(agent_id)
            :immunized
          end

          def carrying?(agent_id:)
            @carriers.include?(agent_id)
          end

          def to_h
            {
              id:                  @id,
              label:               @label,
              contagion_type:      @contagion_type,
              virulence:           @virulence,
              virulence_label:     virulence_label,
              carrier_count:       carrier_count,
              recovered_count:     @recovered.size,
              immune_count:        @immune.size,
              total_transmissions: @total_transmissions,
              transmission_rate:   transmission_rate,
              created_at:          @created_at
            }
          end

          private

          def validate_contagion_type(type)
            Constants::CONTAGION_TYPES.include?(type) ? type : :cognitive
          end
        end
      end
    end
  end
end
