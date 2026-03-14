# lex-bayesian-belief

Bayesian belief updating engine (prior + evidence = posterior) for brain-modeled agentic AI.

## What It Does

Manages the agent's probabilistic beliefs using Bayes' theorem. Each belief has a prior probability that is updated as evidence arrives. The engine computes posteriors, tracks confidence levels, measures uncertainty via entropy, and computes information gain for hypothetical evidence. Beliefs decay toward their priors without reinforcement, modeling the natural fading of unsupported beliefs.

## Core Concept: Bayesian Update

```
posterior = (prior * likelihood) / ((prior * likelihood) + ((1 - prior) * (1 - likelihood)))
```

With `prior = 0.5` and `likelihood = 0.9`, the posterior becomes `≈ 0.9`. With `likelihood = 0.1` (disconfirming evidence), posterior drops to `≈ 0.1`.

## Usage

```ruby
client = Legion::Extensions::BayesianBelief::Client.new

# Add a belief with prior
belief = client.add_bayesian_belief(
  content: 'database bottleneck causes latency spikes',
  domain: :infrastructure,
  prior: 0.3
)

# Update with evidence
client.update_bayesian_belief(
  belief_id: belief[:belief_id],
  evidence_id: 'query_slow_log_spike',
  likelihood: 0.85  # this evidence is 85% likely if belief is true
)
# => { posterior: 0.72, confidence_label: :confident }

# Check uncertainty
client.belief_entropy(domain: :infrastructure)
# => { entropy: 1.2 }  # high entropy = uncertain

# Batch update when new evidence arrives
client.batch_bayesian_update(
  evidence_id: 'cache_miss_spike',
  likelihoods: { belief1_id => 0.8, belief2_id => 0.3 }
)

# Maintenance (decay toward priors)
client.update_bayesian_beliefs
```

## Integration

Pairs with lex-belief-revision for the full belief management stack. Use `belief_entropy` to gate high-stakes decisions — high entropy means the agent should gather more information before acting.

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
