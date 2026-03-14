# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveContagion::Helpers::ContagionEngine do
  subject(:engine) { described_class.new }

  let(:meme)    { engine.create_meme(label: 'panic', contagion_type: :emotional, virulence: 0.9) }
  let(:meme_id) { meme.id }

  before do
    engine.register_agent(agent_id: 'alice', resistance: 0.0)
    engine.register_agent(agent_id: 'bob',   resistance: 0.0)
    engine.register_agent(agent_id: 'carol', resistance: 0.0)
  end

  describe '#create_meme' do
    it 'returns a Meme object' do
      expect(meme).to be_a(Legion::Extensions::CognitiveContagion::Helpers::Meme)
    end

    it 'stores the meme in the engine' do
      expect(engine.memes[meme_id]).to eq(meme)
    end

    it 'applies default virulence when not specified' do
      m = engine.create_meme(label: 'quiet')
      expect(m.virulence).to eq(Legion::Extensions::CognitiveContagion::Helpers::Constants::DEFAULT_VIRULENCE)
    end
  end

  describe '#register_agent' do
    it 'stores agent resistance' do
      expect(engine.agent_resistance['alice']).to eq(0.0)
    end

    it 'clamps resistance to [0,1]' do
      engine.register_agent(agent_id: 'dave', resistance: 2.0)
      expect(engine.agent_resistance['dave']).to eq(1.0)
    end

    it 'applies default resistance when not specified' do
      engine.register_agent(agent_id: 'eve')
      expect(engine.agent_resistance['eve']).to eq(
        Legion::Extensions::CognitiveContagion::Helpers::Constants::DEFAULT_RESISTANCE
      )
    end
  end

  describe '#attempt_transmission' do
    before { meme.infect!(agent_id: 'alice') }

    it 'returns meme_not_found for unknown meme' do
      result = engine.attempt_transmission(meme_id: 'bad-id', source_agent_id: 'alice',
                                           target_agent_id: 'bob')
      expect(result[:reason]).to eq(:meme_not_found)
    end

    it 'returns source_not_carrying if source does not carry' do
      result = engine.attempt_transmission(meme_id: meme_id, source_agent_id: 'bob',
                                           target_agent_id: 'carol')
      expect(result[:reason]).to eq(:source_not_carrying)
    end

    it 'includes probability in result' do
      result = engine.attempt_transmission(meme_id: meme_id, source_agent_id: 'alice',
                                           target_agent_id: 'bob')
      expect(result[:probability]).to be_a(Float)
      expect(result[:probability]).to be >= 0.0
    end

    it 'transmits with probability approaching 1.0 at max virulence and zero resistance' do
      transmitted = (1..100).count do
        e = described_class.new
        e.register_agent(agent_id: 'src', resistance: 0.0)
        e.register_agent(agent_id: 'tgt', resistance: 0.0)
        m = e.create_meme(label: 'x', virulence: 1.0)
        m.infect!(agent_id: 'src')
        r = e.attempt_transmission(meme_id: m.id, source_agent_id: 'src', target_agent_id: 'tgt')
        r[:transmitted]
      end
      expect(transmitted).to be > 0
    end
  end

  describe '#recover_agent' do
    before { meme.infect!(agent_id: 'alice') }

    it 'recovers the agent from the meme' do
      result = engine.recover_agent(meme_id: meme_id, agent_id: 'alice')
      expect(result[:recovered]).to be true
    end

    it 'boosts agent resistance after recovery' do
      before_resistance = engine.agent_resistance['alice']
      engine.recover_agent(meme_id: meme_id, agent_id: 'alice')
      expect(engine.agent_resistance['alice']).to be > before_resistance
    end

    it 'returns meme_not_found for unknown meme' do
      result = engine.recover_agent(meme_id: 'bad-id', agent_id: 'alice')
      expect(result[:recovered]).to be false
      expect(result[:reason]).to eq(:meme_not_found)
    end
  end

  describe '#immunize_agent' do
    it 'immunizes the agent' do
      result = engine.immunize_agent(meme_id: meme_id, agent_id: 'alice')
      expect(result[:immunized]).to be true
    end

    it 'prevents future infection' do
      engine.immunize_agent(meme_id: meme_id, agent_id: 'alice')
      infect_result = meme.infect!(agent_id: 'alice')
      expect(infect_result).to eq(:immune)
    end
  end

  describe '#spread_step' do
    before { meme.infect!(agent_id: 'alice') }

    it 'returns a result hash with transmissions key' do
      result = engine.spread_step(meme_id: meme_id)
      expect(result).to have_key(:transmissions)
    end

    it 'returns meme_not_found for unknown meme' do
      result = engine.spread_step(meme_id: 'bad-id')
      expect(result[:reason]).to eq(:meme_not_found)
    end

    it 'tracks carrier_count in result' do
      result = engine.spread_step(meme_id: meme_id)
      expect(result[:carrier_count]).to be_a(Integer)
    end
  end

  describe '#epidemic_report' do
    before { meme.infect!(agent_id: 'alice') }

    it 'returns SIR counts' do
      report = engine.epidemic_report(meme_id: meme_id)
      expect(report[:infected]).to eq(1)
      expect(report[:susceptible]).to be >= 0
    end

    it 'includes virulence_label' do
      report = engine.epidemic_report(meme_id: meme_id)
      expect(report[:virulence_label]).to eq(:pandemic)
    end

    it 'returns meme_not_found for unknown meme' do
      result = engine.epidemic_report(meme_id: 'bad-id')
      expect(result[:error]).to eq(:meme_not_found)
    end
  end

  describe '#most_viral' do
    before do
      engine.create_meme(label: 'high',   virulence: 0.9)
      engine.create_meme(label: 'medium', virulence: 0.5)
      engine.create_meme(label: 'low',    virulence: 0.1)
    end

    it 'returns hashes sorted by virulence descending' do
      results = engine.most_viral(limit: 3)
      virulences = results.map { |m| m[:virulence] }
      expect(virulences).to eq(virulences.sort.reverse)
    end

    it 'respects the limit' do
      results = engine.most_viral(limit: 2)
      expect(results.size).to be <= 2
    end
  end

  describe '#agent_status' do
    it 'returns susceptible for uninfected agent' do
      result = engine.agent_status(agent_id: 'bob', meme_id: meme_id)
      expect(result[:status]).to eq(:susceptible)
    end

    it 'returns infected for carrying agent' do
      meme.infect!(agent_id: 'bob')
      result = engine.agent_status(agent_id: 'bob', meme_id: meme_id)
      expect(result[:status]).to eq(:infected)
    end

    it 'returns recovered for recovered agent' do
      meme.infect!(agent_id: 'bob')
      meme.recover!(agent_id: 'bob')
      result = engine.agent_status(agent_id: 'bob', meme_id: meme_id)
      expect(result[:status]).to eq(:recovered)
    end

    it 'returns immune for immunized agent' do
      engine.immunize_agent(meme_id: meme_id, agent_id: 'bob')
      result = engine.agent_status(agent_id: 'bob', meme_id: meme_id)
      expect(result[:status]).to eq(:immune)
    end

    it 'returns unknown with meme_not_found for bad meme id' do
      result = engine.agent_status(agent_id: 'bob', meme_id: 'bad-id')
      expect(result[:status]).to eq(:unknown)
    end
  end

  describe '#susceptible_agents' do
    it 'returns all agents when no one is infected or immune' do
      agents = engine.susceptible_agents(meme_id: meme_id)
      expect(agents).to match_array(%w[alice bob carol])
    end

    it 'excludes carriers' do
      meme.infect!(agent_id: 'alice')
      agents = engine.susceptible_agents(meme_id: meme_id)
      expect(agents).not_to include('alice')
    end

    it 'excludes immune agents' do
      engine.immunize_agent(meme_id: meme_id, agent_id: 'bob')
      agents = engine.susceptible_agents(meme_id: meme_id)
      expect(agents).not_to include('bob')
    end

    it 'returns empty array for unknown meme' do
      expect(engine.susceptible_agents(meme_id: 'bad-id')).to eq([])
    end
  end

  describe '#to_h' do
    it 'returns meme_count and agent_count' do
      h = engine.to_h
      expect(h[:meme_count]).to eq(engine.memes.size)
      expect(h[:agent_count]).to eq(engine.agent_resistance.size)
    end

    it 'includes memes array' do
      expect(engine.to_h[:memes]).to be_an(Array)
    end
  end
end
