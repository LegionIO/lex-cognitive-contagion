# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveContagion::Helpers::Meme do
  subject(:meme) { described_class.new(label: 'test-meme', contagion_type: :belief, virulence: 0.6) }

  describe '#initialize' do
    it 'assigns a uuid id' do
      expect(meme.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'stores the label' do
      expect(meme.label).to eq('test-meme')
    end

    it 'stores the contagion_type' do
      expect(meme.contagion_type).to eq(:belief)
    end

    it 'clamps virulence to [0,1]' do
      m = described_class.new(label: 'x', virulence: 1.5)
      expect(m.virulence).to eq(1.0)
    end

    it 'clamps virulence lower bound' do
      m = described_class.new(label: 'x', virulence: -0.5)
      expect(m.virulence).to eq(0.0)
    end

    it 'starts with empty carrier set' do
      expect(meme.carriers).to be_empty
    end

    it 'starts with empty recovered set' do
      expect(meme.recovered).to be_empty
    end

    it 'starts with empty immune set' do
      expect(meme.immune).to be_empty
    end

    it 'starts with zero total_transmissions' do
      expect(meme.total_transmissions).to eq(0)
    end

    it 'defaults unknown contagion_type to :cognitive' do
      m = described_class.new(label: 'x', contagion_type: :invalid)
      expect(m.contagion_type).to eq(:cognitive)
    end
  end

  describe '#virulence_label' do
    it 'returns :epidemic for 0.6' do
      expect(meme.virulence_label).to eq(:epidemic)
    end

    it 'returns :pandemic for 0.9' do
      m = described_class.new(label: 'x', virulence: 0.9)
      expect(m.virulence_label).to eq(:pandemic)
    end

    it 'returns :contained for 0.1' do
      m = described_class.new(label: 'x', virulence: 0.1)
      expect(m.virulence_label).to eq(:contained)
    end
  end

  describe '#infect!' do
    it 'adds agent to carriers and returns :infected' do
      result = meme.infect!(agent_id: 'agent-1')
      expect(result).to eq(:infected)
      expect(meme.carriers).to include('agent-1')
    end

    it 'returns :already_carrier for a second infect call' do
      meme.infect!(agent_id: 'agent-1')
      expect(meme.infect!(agent_id: 'agent-1')).to eq(:already_carrier)
    end

    it 'returns :immune if agent is immune' do
      meme.immunize!(agent_id: 'agent-1')
      expect(meme.infect!(agent_id: 'agent-1')).to eq(:immune)
    end

    it 'increments total_transmissions' do
      meme.infect!(agent_id: 'agent-1')
      expect(meme.total_transmissions).to eq(1)
    end
  end

  describe '#recover!' do
    before { meme.infect!(agent_id: 'agent-1') }

    it 'removes from carriers and adds to recovered' do
      result = meme.recover!(agent_id: 'agent-1')
      expect(result).to eq(:recovered)
      expect(meme.carriers).not_to include('agent-1')
      expect(meme.recovered).to include('agent-1')
    end

    it 'returns :not_a_carrier if not carrying' do
      expect(meme.recover!(agent_id: 'nobody')).to eq(:not_a_carrier)
    end
  end

  describe '#immunize!' do
    it 'adds to immune set' do
      meme.immunize!(agent_id: 'agent-1')
      expect(meme.immune).to include('agent-1')
    end

    it 'removes from carriers if carrying' do
      meme.infect!(agent_id: 'agent-1')
      meme.immunize!(agent_id: 'agent-1')
      expect(meme.carriers).not_to include('agent-1')
    end
  end

  describe '#carrying?' do
    it 'returns true when agent is a carrier' do
      meme.infect!(agent_id: 'agent-1')
      expect(meme.carrying?(agent_id: 'agent-1')).to be true
    end

    it 'returns false when agent is not a carrier' do
      expect(meme.carrying?(agent_id: 'nobody')).to be false
    end
  end

  describe '#carrier_count' do
    it 'returns zero initially' do
      expect(meme.carrier_count).to eq(0)
    end

    it 'returns count after infection' do
      meme.infect!(agent_id: 'a')
      meme.infect!(agent_id: 'b')
      expect(meme.carrier_count).to eq(2)
    end
  end

  describe '#transmission_rate' do
    it 'returns 0.0 with no carriers' do
      expect(meme.transmission_rate).to eq(0.0)
    end

    it 'returns ratio of transmissions to carriers' do
      meme.infect!(agent_id: 'a')
      expect(meme.transmission_rate).to be > 0.0
    end
  end

  describe '#to_h' do
    it 'returns a hash with expected keys' do
      h = meme.to_h
      expect(h.keys).to include(:id, :label, :contagion_type, :virulence, :virulence_label,
                                :carrier_count, :recovered_count, :immune_count,
                                :total_transmissions, :transmission_rate, :created_at)
    end
  end
end
