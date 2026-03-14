# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveContagion::Helpers::Constants do
  describe 'numeric constants' do
    it 'defines MAX_AGENTS' do
      expect(described_class::MAX_AGENTS).to eq(200)
    end

    it 'defines MAX_MEMES' do
      expect(described_class::MAX_MEMES).to eq(500)
    end

    it 'defines DEFAULT_VIRULENCE' do
      expect(described_class::DEFAULT_VIRULENCE).to eq(0.3)
    end

    it 'defines DEFAULT_RESISTANCE' do
      expect(described_class::DEFAULT_RESISTANCE).to eq(0.5)
    end

    it 'defines TRANSMISSION_RATE' do
      expect(described_class::TRANSMISSION_RATE).to eq(0.15)
    end

    it 'defines RECOVERY_RATE' do
      expect(described_class::RECOVERY_RATE).to eq(0.05)
    end

    it 'defines IMMUNITY_BOOST' do
      expect(described_class::IMMUNITY_BOOST).to eq(0.1)
    end
  end

  describe 'VIRULENCE_LABELS' do
    let(:labels) { described_class::VIRULENCE_LABELS }

    it 'maps 0.9 to pandemic' do
      result = labels.find { |range, _| range.cover?(0.9) }&.last
      expect(result).to eq(:pandemic)
    end

    it 'maps 0.7 to epidemic' do
      result = labels.find { |range, _| range.cover?(0.7) }&.last
      expect(result).to eq(:epidemic)
    end

    it 'maps 0.5 to endemic' do
      result = labels.find { |range, _| range.cover?(0.5) }&.last
      expect(result).to eq(:endemic)
    end

    it 'maps 0.3 to sporadic' do
      result = labels.find { |range, _| range.cover?(0.3) }&.last
      expect(result).to eq(:sporadic)
    end

    it 'maps 0.1 to contained' do
      result = labels.find { |range, _| range.cover?(0.1) }&.last
      expect(result).to eq(:contained)
    end

    it 'is frozen' do
      expect(labels).to be_frozen
    end
  end

  describe 'STATUS_LABELS' do
    it 'contains all five states' do
      expect(described_class::STATUS_LABELS).to eq(%i[susceptible exposed infected recovered immune])
    end

    it 'is frozen' do
      expect(described_class::STATUS_LABELS).to be_frozen
    end
  end

  describe 'CONTAGION_TYPES' do
    it 'contains four types' do
      expect(described_class::CONTAGION_TYPES).to eq(%i[emotional belief behavioral cognitive])
    end

    it 'is frozen' do
      expect(described_class::CONTAGION_TYPES).to be_frozen
    end
  end
end
