# frozen_string_literal: true

module Legion
  module Extensions
    module CognitiveContagion
      module Helpers
        class ContagionEngine
          attr_reader :memes, :agent_resistance

          def initialize
            @memes            = {}
            @agent_resistance = {}
          end

          def create_meme(label:, contagion_type: :cognitive, virulence: Constants::DEFAULT_VIRULENCE)
            return { error: :too_many_memes } if @memes.size >= Constants::MAX_MEMES

            meme = Meme.new(label: label, contagion_type: contagion_type, virulence: virulence)
            @memes[meme.id] = meme
            meme
          end

          def register_agent(agent_id:, resistance: Constants::DEFAULT_RESISTANCE)
            return { error: :too_many_agents } if @agent_resistance.size >= Constants::MAX_AGENTS

            @agent_resistance[agent_id] = resistance.clamp(0.0, 1.0).round(10)
            { agent_id: agent_id, resistance: @agent_resistance[agent_id] }
          end

          def attempt_transmission(meme_id:, source_agent_id:, target_agent_id:)
            meme = @memes.fetch(meme_id, nil)
            return { transmitted: false, reason: :meme_not_found } unless meme
            return { transmitted: false, reason: :source_not_carrying } unless meme.carrying?(agent_id: source_agent_id)

            resistance = @agent_resistance.fetch(target_agent_id, Constants::DEFAULT_RESISTANCE)
            probability = (meme.virulence * Constants::TRANSMISSION_RATE * (1.0 - resistance)).round(10)

            if rand <= probability
              result = meme.infect!(agent_id: target_agent_id)
              { transmitted: result == :infected, reason: result, meme_id: meme_id,
                source: source_agent_id, target: target_agent_id, probability: probability }
            else
              { transmitted: false, reason: :blocked_by_resistance, meme_id: meme_id,
                source: source_agent_id, target: target_agent_id, probability: probability }
            end
          end

          def recover_agent(meme_id:, agent_id:)
            meme = @memes.fetch(meme_id, nil)
            return { recovered: false, reason: :meme_not_found } unless meme

            result = meme.recover!(agent_id: agent_id)
            boost_resistance(agent_id)
            { recovered: result == :recovered, agent_id: agent_id, meme_id: meme_id, result: result }
          end

          def immunize_agent(meme_id:, agent_id:)
            meme = @memes.fetch(meme_id, nil)
            return { immunized: false, reason: :meme_not_found } unless meme

            result = meme.immunize!(agent_id: agent_id)
            { immunized: true, agent_id: agent_id, meme_id: meme_id, result: result }
          end

          def spread_step(meme_id:)
            meme = @memes.fetch(meme_id, nil)
            return { transmissions: 0, reason: :meme_not_found } unless meme

            susceptible = susceptible_agents(meme_id: meme_id)
            carriers    = meme.carriers.to_a
            transmissions = 0

            carriers.each do |carrier_id|
              susceptible.each do |target_id|
                result = attempt_transmission(meme_id: meme_id, source_agent_id: carrier_id,
                                              target_agent_id: target_id)
                transmissions += 1 if result[:transmitted]
              end
            end

            recoveries = apply_natural_recovery(meme_id: meme_id)
            { meme_id: meme_id, transmissions: transmissions, recoveries: recoveries,
              carrier_count: meme.carrier_count }
          end

          def epidemic_report(meme_id:)
            meme = @memes.fetch(meme_id, nil)
            return { error: :meme_not_found } unless meme

            total = @agent_resistance.size
            infected   = meme.carriers.size
            recovered  = meme.recovered.size
            immune     = meme.immune.size
            susceptible_count = [total - infected - recovered - immune, 0].max

            {
              meme_id:             meme_id,
              label:               meme.label,
              contagion_type:      meme.contagion_type,
              virulence:           meme.virulence,
              virulence_label:     meme.virulence_label,
              susceptible:         susceptible_count,
              infected:            infected,
              recovered:           recovered,
              immune:              immune,
              total_agents:        total,
              total_transmissions: meme.total_transmissions,
              transmission_rate:   meme.transmission_rate
            }
          end

          def most_viral(limit: 5)
            @memes.values
                  .sort_by { |m| -m.virulence }
                  .first(limit)
                  .map(&:to_h)
          end

          def agent_status(agent_id:, meme_id:)
            meme = @memes.fetch(meme_id, nil)
            return { status: :unknown, reason: :meme_not_found } unless meme

            status = if meme.immune.include?(agent_id)
                       :immune
                     elsif meme.carrying?(agent_id: agent_id)
                       :infected
                     elsif meme.recovered.include?(agent_id)
                       :recovered
                     else
                       :susceptible
                     end

            { agent_id: agent_id, meme_id: meme_id, status: status,
              resistance: @agent_resistance.fetch(agent_id, Constants::DEFAULT_RESISTANCE) }
          end

          def susceptible_agents(meme_id:)
            meme = @memes.fetch(meme_id, nil)
            return [] unless meme

            @agent_resistance.keys.reject do |id|
              meme.carrying?(agent_id: id) || meme.immune.include?(id)
            end
          end

          def to_h
            {
              meme_count:       @memes.size,
              agent_count:      @agent_resistance.size,
              memes:            @memes.values.map(&:to_h),
              agent_resistance: @agent_resistance
            }
          end

          private

          def boost_resistance(agent_id)
            current = @agent_resistance.fetch(agent_id, Constants::DEFAULT_RESISTANCE)
            @agent_resistance[agent_id] = (current + Constants::IMMUNITY_BOOST).clamp(0.0, 1.0).round(10)
          end

          def apply_natural_recovery(meme_id:)
            meme = @memes.fetch(meme_id, nil)
            return 0 unless meme

            recoveries = 0
            meme.carriers.to_a.each do |carrier_id|
              next unless rand <= Constants::RECOVERY_RATE

              meme.recover!(agent_id: carrier_id)
              boost_resistance(carrier_id)
              recoveries += 1
            end
            recoveries
          end
        end
      end
    end
  end
end
