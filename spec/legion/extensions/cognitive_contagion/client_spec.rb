# frozen_string_literal: true

require 'legion/extensions/cognitive_contagion/client'

RSpec.describe Legion::Extensions::CognitiveContagion::Client do
  let(:client) { described_class.new }

  it 'responds to create_meme' do
    expect(client).to respond_to(:create_meme)
  end

  it 'responds to register_agent' do
    expect(client).to respond_to(:register_agent)
  end

  it 'responds to attempt_transmission' do
    expect(client).to respond_to(:attempt_transmission)
  end

  it 'responds to recover_agent' do
    expect(client).to respond_to(:recover_agent)
  end

  it 'responds to infect_agent' do
    expect(client).to respond_to(:infect_agent)
  end

  it 'responds to immunize_agent' do
    expect(client).to respond_to(:immunize_agent)
  end

  it 'responds to spread_step' do
    expect(client).to respond_to(:spread_step)
  end

  it 'responds to epidemic_report' do
    expect(client).to respond_to(:epidemic_report)
  end

  it 'responds to most_viral' do
    expect(client).to respond_to(:most_viral)
  end

  it 'responds to agent_status' do
    expect(client).to respond_to(:agent_status)
  end

  it 'responds to susceptible_agents' do
    expect(client).to respond_to(:susceptible_agents)
  end

  it 'responds to contagion_status' do
    expect(client).to respond_to(:contagion_status)
  end

  it 'can perform a full create->infect->report cycle' do
    client.register_agent(agent_id: 'agent-a', resistance: 0.0)
    meme = client.create_meme(label: 'fear', virulence: 0.8)
    client.infect_agent(meme_id: meme[:id], agent_id: 'agent-a')
    report = client.epidemic_report(meme_id: meme[:id])
    expect(report[:infected]).to eq(1)
  end
end
