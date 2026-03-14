# frozen_string_literal: true

module Legion
  module Extensions
    module CognitiveContagion
      module Runners
        module CognitiveContagion
          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)

          def create_meme(label:, contagion_type: :cognitive, virulence: nil, **)
            v      = virulence || Helpers::Constants::DEFAULT_VIRULENCE
            result = engine.create_meme(label: label, contagion_type: contagion_type, virulence: v)

            if result.is_a?(Hash) && result[:error]
              Legion::Logging.warn "[cognitive_contagion] create_meme failed: #{result[:error]}"
              return result
            end

            Legion::Logging.info "[cognitive_contagion] meme created: id=#{result.id} label=#{label} " \
                                 "virulence=#{result.virulence} type=#{contagion_type}"
            result.to_h
          end

          def register_agent(agent_id:, resistance: nil, **)
            r      = resistance || Helpers::Constants::DEFAULT_RESISTANCE
            result = engine.register_agent(agent_id: agent_id, resistance: r)

            if result.is_a?(Hash) && result[:error]
              Legion::Logging.warn "[cognitive_contagion] register_agent failed: #{result[:error]}"
              return result
            end

            Legion::Logging.debug "[cognitive_contagion] agent registered: id=#{agent_id} resistance=#{r}"
            result
          end

          def attempt_transmission(meme_id:, source_agent_id:, target_agent_id:, **)
            result = engine.attempt_transmission(
              meme_id:         meme_id,
              source_agent_id: source_agent_id,
              target_agent_id: target_agent_id
            )
            Legion::Logging.debug "[cognitive_contagion] transmission: meme=#{meme_id} " \
                                  "#{source_agent_id}->#{target_agent_id} transmitted=#{result[:transmitted]}"
            result
          end

          def recover_agent(meme_id:, agent_id:, **)
            result = engine.recover_agent(meme_id: meme_id, agent_id: agent_id)
            Legion::Logging.debug "[cognitive_contagion] recover: meme=#{meme_id} agent=#{agent_id} " \
                                  "result=#{result[:result]}"
            result
          end

          def infect_agent(meme_id:, agent_id:, **)
            meme = engine.memes[meme_id]
            return { infected: false, reason: :meme_not_found } unless meme

            result = meme.infect!(agent_id: agent_id)
            Legion::Logging.debug "[cognitive_contagion] infect_agent: meme=#{meme_id} agent=#{agent_id} result=#{result}"
            { infected: result == :infected, agent_id: agent_id, meme_id: meme_id, result: result }
          end

          def immunize_agent(meme_id:, agent_id:, **)
            result = engine.immunize_agent(meme_id: meme_id, agent_id: agent_id)
            Legion::Logging.debug "[cognitive_contagion] immunize: meme=#{meme_id} agent=#{agent_id}"
            result
          end

          def spread_step(meme_id:, **)
            result = engine.spread_step(meme_id: meme_id)
            Legion::Logging.info "[cognitive_contagion] spread_step: meme=#{meme_id} " \
                                 "transmissions=#{result[:transmissions]} recoveries=#{result[:recoveries]}"
            result
          end

          def epidemic_report(meme_id:, **)
            result = engine.epidemic_report(meme_id: meme_id)
            Legion::Logging.debug "[cognitive_contagion] epidemic_report: meme=#{meme_id} " \
                                  "infected=#{result[:infected]} virulence_label=#{result[:virulence_label]}"
            result
          end

          def most_viral(limit: 5, **)
            results = engine.most_viral(limit: limit)
            Legion::Logging.debug "[cognitive_contagion] most_viral: limit=#{limit} count=#{results.size}"
            { memes: results, count: results.size }
          end

          def agent_status(agent_id:, meme_id:, **)
            result = engine.agent_status(agent_id: agent_id, meme_id: meme_id)
            Legion::Logging.debug "[cognitive_contagion] agent_status: agent=#{agent_id} " \
                                  "meme=#{meme_id} status=#{result[:status]}"
            result
          end

          def susceptible_agents(meme_id:, **)
            agents = engine.susceptible_agents(meme_id: meme_id)
            Legion::Logging.debug "[cognitive_contagion] susceptible_agents: meme=#{meme_id} count=#{agents.size}"
            { agents: agents, count: agents.size, meme_id: meme_id }
          end

          def contagion_status(**)
            Legion::Logging.debug '[cognitive_contagion] contagion_status requested'
            summary = engine.to_h.slice(:meme_count, :agent_count)
            summary.merge(contagion_types: Helpers::Constants::CONTAGION_TYPES,
                          max_agents:      Helpers::Constants::MAX_AGENTS,
                          max_memes:       Helpers::Constants::MAX_MEMES)
          end

          private

          def engine
            @engine ||= Helpers::ContagionEngine.new
          end
        end
      end
    end
  end
end
