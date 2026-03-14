# lex-cognitive-contagion

SIR-inspired cognitive/emotional contagion modeling for brain-modeled agentic AI. Models how beliefs, emotions, behaviors, and cognitive patterns spread between agents.

## What It Does

Belief systems and emotional states spread between agents like infections. This extension models that propagation using epidemiological SIR dynamics: susceptible agents can be exposed, infected agents spread the meme, recovered agents gain resistance, and immunized agents are fully protected. Four contagion types are supported: emotional, belief, behavioral, and cognitive.

Each agent has a resistance score; each meme has a virulence score. Transmission probability is a function of both. `spread_step` runs one simulation timestep: attempting transmissions and applying natural recovery.

## Usage

```ruby
client = Legion::Extensions::CognitiveContagion::Client.new

meme = client.create_meme(
  label: 'catastrophizing',
  contagion_type: :cognitive,
  virulence: 0.6
)

client.register_agent(agent_id: 'agent_alpha', resistance: 0.4)
client.register_agent(agent_id: 'agent_beta', resistance: 0.7)

client.infect_agent(meme_id: meme.id, agent_id: 'agent_alpha')
client.spread_step(meme_id: meme.id)

client.epidemic_report(meme_id: meme.id)
# => { susceptible: 0, infected: 1, recovered: 1, virulence_label: :epidemic }
```

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
