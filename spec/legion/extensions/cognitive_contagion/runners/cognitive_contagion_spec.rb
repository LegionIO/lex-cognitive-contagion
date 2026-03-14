# frozen_string_literal: true

require 'legion/extensions/cognitive_contagion/client'

RSpec.describe Legion::Extensions::CognitiveContagion::Runners::CognitiveContagion do
  let(:client) { Legion::Extensions::CognitiveContagion::Client.new }

  let(:meme_result) { client.create_meme(label: 'test-meme', contagion_type: :belief, virulence: 0.7) }
  let(:meme_id)     { meme_result[:id] }

  before do
    client.register_agent(agent_id: 'alice', resistance: 0.0)
    client.register_agent(agent_id: 'bob',   resistance: 0.0)
    client.register_agent(agent_id: 'carol', resistance: 0.8)
  end

  describe '#create_meme' do
    it 'returns a hash with id' do
      expect(meme_result[:id]).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'returns the label' do
      expect(meme_result[:label]).to eq('test-meme')
    end

    it 'returns virulence_label' do
      expect(meme_result[:virulence_label]).to eq(:epidemic)
    end

    it 'uses default virulence when not provided' do
      result = client.create_meme(label: 'quiet')
      expect(result[:virulence]).to eq(Legion::Extensions::CognitiveContagion::Helpers::Constants::DEFAULT_VIRULENCE)
    end
  end

  describe '#register_agent' do
    it 'returns agent_id and resistance' do
      result = client.register_agent(agent_id: 'dave', resistance: 0.3)
      expect(result[:agent_id]).to eq('dave')
      expect(result[:resistance]).to eq(0.3)
    end

    it 'uses default resistance when not provided' do
      result = client.register_agent(agent_id: 'eve')
      expect(result[:resistance]).to eq(
        Legion::Extensions::CognitiveContagion::Helpers::Constants::DEFAULT_RESISTANCE
      )
    end
  end

  describe '#infect_agent' do
    it 'infects the agent and returns infected: true' do
      result = client.infect_agent(meme_id: meme_id, agent_id: 'alice')
      expect(result[:infected]).to be true
      expect(result[:result]).to eq(:infected)
    end

    it 'returns already_carrier on second call' do
      client.infect_agent(meme_id: meme_id, agent_id: 'alice')
      result = client.infect_agent(meme_id: meme_id, agent_id: 'alice')
      expect(result[:result]).to eq(:already_carrier)
    end

    it 'returns meme_not_found for unknown meme' do
      result = client.infect_agent(meme_id: 'bad-id', agent_id: 'alice')
      expect(result[:infected]).to be false
      expect(result[:reason]).to eq(:meme_not_found)
    end
  end

  describe '#attempt_transmission' do
    before { client.infect_agent(meme_id: meme_id, agent_id: 'alice') }

    it 'returns a result with transmitted key' do
      result = client.attempt_transmission(meme_id: meme_id, source_agent_id: 'alice',
                                           target_agent_id: 'bob')
      expect(result).to have_key(:transmitted)
    end

    it 'returns meme_not_found for unknown meme' do
      result = client.attempt_transmission(meme_id: 'bad', source_agent_id: 'alice',
                                           target_agent_id: 'bob')
      expect(result[:reason]).to eq(:meme_not_found)
    end
  end

  describe '#recover_agent' do
    before { client.infect_agent(meme_id: meme_id, agent_id: 'alice') }

    it 'returns recovered true' do
      result = client.recover_agent(meme_id: meme_id, agent_id: 'alice')
      expect(result[:recovered]).to be true
    end

    it 'handles unknown meme gracefully' do
      result = client.recover_agent(meme_id: 'bad', agent_id: 'alice')
      expect(result[:recovered]).to be false
    end
  end

  describe '#immunize_agent' do
    it 'returns immunized true' do
      result = client.immunize_agent(meme_id: meme_id, agent_id: 'alice')
      expect(result[:immunized]).to be true
    end
  end

  describe '#spread_step' do
    before { client.infect_agent(meme_id: meme_id, agent_id: 'alice') }

    it 'returns a hash with transmissions' do
      result = client.spread_step(meme_id: meme_id)
      expect(result).to have_key(:transmissions)
      expect(result[:transmissions]).to be_a(Integer)
    end

    it 'returns meme_not_found reason for bad meme' do
      result = client.spread_step(meme_id: 'bad')
      expect(result[:reason]).to eq(:meme_not_found)
    end
  end

  describe '#epidemic_report' do
    before { client.infect_agent(meme_id: meme_id, agent_id: 'alice') }

    it 'returns SIR statistics' do
      report = client.epidemic_report(meme_id: meme_id)
      expect(report[:infected]).to eq(1)
      expect(report[:susceptible]).to be >= 0
      expect(report[:recovered]).to eq(0)
    end

    it 'includes virulence_label' do
      report = client.epidemic_report(meme_id: meme_id)
      expect(report).to have_key(:virulence_label)
    end
  end

  describe '#most_viral' do
    before do
      client.create_meme(label: 'high',   virulence: 0.95)
      client.create_meme(label: 'low',    virulence: 0.05)
    end

    it 'returns a hash with memes array' do
      result = client.most_viral
      expect(result[:memes]).to be_an(Array)
    end

    it 'returns count of memes' do
      result = client.most_viral(limit: 2)
      expect(result[:count]).to be <= 2
    end

    it 'sorts by virulence descending' do
      result = client.most_viral
      virulences = result[:memes].map { |m| m[:virulence] }
      expect(virulences).to eq(virulences.sort.reverse)
    end
  end

  describe '#agent_status' do
    it 'returns susceptible for uninfected registered agent' do
      result = client.agent_status(agent_id: 'bob', meme_id: meme_id)
      expect(result[:status]).to eq(:susceptible)
    end

    it 'returns infected after infection' do
      client.infect_agent(meme_id: meme_id, agent_id: 'bob')
      result = client.agent_status(agent_id: 'bob', meme_id: meme_id)
      expect(result[:status]).to eq(:infected)
    end

    it 'returns immune after immunization' do
      client.immunize_agent(meme_id: meme_id, agent_id: 'carol')
      result = client.agent_status(agent_id: 'carol', meme_id: meme_id)
      expect(result[:status]).to eq(:immune)
    end
  end

  describe '#susceptible_agents' do
    it 'returns agents and count' do
      result = client.susceptible_agents(meme_id: meme_id)
      expect(result[:agents]).to be_an(Array)
      expect(result[:count]).to eq(result[:agents].size)
    end

    it 'returns meme_id in result' do
      result = client.susceptible_agents(meme_id: meme_id)
      expect(result[:meme_id]).to eq(meme_id)
    end
  end

  describe '#contagion_status' do
    it 'returns meme_count and agent_count' do
      result = client.contagion_status
      expect(result[:meme_count]).to be_a(Integer)
      expect(result[:agent_count]).to be_a(Integer)
    end

    it 'returns contagion_types list' do
      expect(client.contagion_status[:contagion_types]).to eq(%i[emotional belief behavioral cognitive])
    end

    it 'returns max_agents and max_memes' do
      result = client.contagion_status
      expect(result[:max_agents]).to eq(200)
      expect(result[:max_memes]).to eq(500)
    end
  end
end
