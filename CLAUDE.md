# lex-cognitive-contagion

**Level 3 Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Grandparent**: `/Users/miverso2/rubymine/legion/CLAUDE.md`

## Purpose

SIR-inspired cognitive/emotional contagion modeling for brain-modeled agentic AI. Models how beliefs, emotions, behaviors, and cognitive patterns spread between agents using epidemiological dynamics: susceptible -> exposed -> infected -> recovered -> immune. Tracks transmission rates, virulence, and resistance across a registered agent population.

## Gem Info

- **Gem name**: `lex-cognitive-contagion`
- **Version**: `0.1.0`
- **Module**: `Legion::Extensions::CognitiveContagion`
- **Ruby**: `>= 3.4`
- **License**: MIT

## File Structure

```
lib/legion/extensions/cognitive_contagion/
  cognitive_contagion.rb
  version.rb
  client.rb
  helpers/
    constants.rb
    contagion_engine.rb
    meme.rb
  runners/
    cognitive_contagion.rb
```

## Key Constants

From `helpers/constants.rb`:

- `CONTAGION_TYPES` — `%i[emotional belief behavioral cognitive]`
- `STATUS_LABELS` — `%i[susceptible exposed infected recovered immune]`
- `MAX_AGENTS` = `200`, `MAX_MEMES` = `500`
- `DEFAULT_VIRULENCE` = `0.3`, `DEFAULT_RESISTANCE` = `0.5`
- `TRANSMISSION_RATE` = `0.15`, `RECOVERY_RATE` = `0.05`, `IMMUNITY_BOOST` = `0.1`
- `VIRULENCE_LABELS` — `0.8+` = `:pandemic`, `0.6` = `:epidemic`, `0.4` = `:endemic`, `0.2` = `:sporadic`, below = `:contained`

## Runners

All methods in `Runners::CognitiveContagion`:

- `create_meme(label:, contagion_type: :cognitive, virulence: DEFAULT_VIRULENCE)` — creates a contagious cognitive meme; returns meme object directly (not wrapped)
- `register_agent(agent_id:, resistance: DEFAULT_RESISTANCE)` — registers an agent in the susceptible population
- `attempt_transmission(meme_id:, source_agent_id:, target_agent_id:)` — tries to transmit meme from source to target; success depends on virulence vs resistance
- `recover_agent(meme_id:, agent_id:)` — moves agent from infected to recovered state
- `infect_agent(meme_id:, agent_id:)` — directly infects an agent (bypasses resistance)
- `immunize_agent(meme_id:, agent_id:)` — grants immunity to a specific agent for a specific meme
- `spread_step(meme_id:)` — runs one full epidemic step: attempts transmissions and applies recovery rate; returns transmission/recovery counts
- `epidemic_report(meme_id:)` — SIR breakdown for a specific meme: susceptible/exposed/infected/recovered counts, virulence label
- `most_viral(limit: 5)` — top memes by infection rate
- `agent_status(agent_id:, meme_id:)` — current SIR status of an agent for a meme
- `susceptible_agents(meme_id:)` — all susceptible agents for a meme
- `contagion_status` — aggregate: meme count, agent count, type list, limits

## Helpers

- `ContagionEngine` — manages memes and agents. `spread_step` is the epidemic simulation step.
- `Meme` — contagious cognitive pattern with `contagion_type`, `virulence`, per-agent SIR status. `infect!(agent_id:)` changes status to `:infected`.

## Integration Points

- `lex-mesh` provides the agent-to-agent communication layer; contagion models what spreads over that mesh when agents interact.
- `lex-cognitive-echo-chamber` models self-reinforcement within a single agent; contagion models inter-agent spread across the mesh.
- `lex-cognitive-empathy` emotional contagion mechanism parallels this SIR model — empathy spreads emotional states via contagion dynamics.

## Development Notes

- `create_meme` returns the meme object directly (not wrapped in `{ success:, meme: }`) — callers access `.id`, `.virulence` directly. Runner logs via `Legion::Logging.info`.
- `register_agent` also returns the result directly, not wrapped. Check for `result.is_a?(Hash) && result[:error]` to detect failure.
- `spread_step` is a simulation step — callers drive the epidemic simulation by calling it repeatedly.
- `attempt_transmission` succeeds when a random draw against `virulence * (1 - resistance)` passes.
