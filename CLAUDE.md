# lex-bayesian-belief

**Level 3 Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Grandparent**: `/Users/miverso2/rubymine/legion/CLAUDE.md`

## Purpose

Bayesian belief updating engine (prior + evidence = posterior) for brain-modeled agentic AI. Implements principled probabilistic belief management: beliefs have prior probabilities that are updated via Bayes' theorem when evidence arrives, producing posteriors. Supports batch updates, information gain computation, and entropy measurement across belief distributions.

## Gem Info

- **Gem name**: `lex-bayesian-belief`
- **Version**: `0.1.0`
- **Module**: `Legion::Extensions::BayesianBelief`
- **Ruby**: `>= 3.4`
- **License**: MIT

## File Structure

```
lib/legion/extensions/bayesian_belief/
  bayesian_belief.rb             # Main extension module
  version.rb                     # VERSION = '0.1.0'
  client.rb                      # Client wrapper
  helpers/
    constants.rb                 # Capacity, probability bounds, decay, confidence labels
    belief.rb                    # Belief value object (prior, posterior, update history)
    belief_network.rb            # BeliefNetwork — Bayesian updating, entropy, information gain
  runners/
    bayesian_belief.rb           # Runner module with 9 public methods
spec/
  (spec files)
```

## Key Constants

```ruby
MAX_HYPOTHESES     = 200
MAX_EVIDENCE       = 500
MAX_HISTORY        = 300
DEFAULT_PRIOR      = 0.5
PRIOR_FLOOR        = 0.001    # prevents probability collapse to 0
PRIOR_CEILING      = 0.999    # prevents probability collapse to 1
LIKELIHOOD_FLOOR   = 0.001
LIKELIHOOD_CEILING = 0.999
DECAY_RATE         = 0.01     # posterior drifts toward prior when no evidence
STALE_THRESHOLD    = 120      # seconds

CONFIDENCE_LABELS = {
  (0.9..) => :certain, (0.7...0.9) => :confident, (0.5...0.7) => :leaning,
  (0.3...0.5) => :uncertain, (..0.3) => :doubtful
}
```

## Runners

### `Runners::BayesianBelief`

All methods delegate to a private `@belief_network` (`Helpers::BeliefNetwork` instance).

- `add_bayesian_belief(content:, domain:, prior: nil)` — add a new belief with prior probability; prior defaults to `DEFAULT_PRIOR`
- `update_bayesian_belief(belief_id:, evidence_id:, likelihood:)` — apply Bayesian update: `posterior = prior * likelihood / marginal`; returns new posterior and confidence_label
- `batch_bayesian_update(evidence_id:, likelihoods:)` — update multiple beliefs with a single piece of evidence; `likelihoods` is a hash of `belief_id => likelihood`
- `most_probable_beliefs(domain: nil, limit: 5)` — top beliefs by posterior
- `least_probable_beliefs(domain: nil, limit: 5)` — bottom beliefs by posterior
- `posterior_distribution(domain: nil)` — full distribution hash of `belief_id => posterior`
- `information_gain(belief_id:, evidence_id:, likelihood:)` — compute KL divergence before/after hypothetical update
- `belief_entropy(domain: nil)` — Shannon entropy of the posterior distribution
- `update_bayesian_beliefs` — decay all posteriors toward prior (stale beliefs regress)
- `bayesian_belief_stats` — total, entropy, most/least probable

## Helpers

### `Helpers::BeliefNetwork`
Core engine. Bayesian update: `posterior = (prior * likelihood) / ((prior * likelihood) + ((1 - prior) * (1 - likelihood)))`. Handles complementary evidence automatically. `batch_update` applies the same evidence_id to multiple beliefs. `entropy` computes `-sum(p * log2(p))` over the posterior distribution. `information_gain` = `abs(new_posterior - old_posterior)` (simplified KL approximation).

### `Helpers::Belief`
Value object: content, domain, prior, posterior, update_count, created_at, last_updated_at, confidence_label derived from posterior.

## Integration Points

No actor defined — callers drive decay via `update_bayesian_beliefs`. Pairs with lex-belief-revision: Bayesian belief maintains the probabilistic model while belief-revision handles qualitative network links (supports/undermines/entails). Together they form the full belief management stack. `belief_entropy` measures epistemic uncertainty — high entropy → agent should seek more information before acting. Wire entropy output into lex-tick's action_selection to gate high-stakes actions when uncertainty is high.

## Development Notes

- Bayesian update formula uses a two-hypothesis model (P(H) and P(not-H)); for multi-hypothesis problems, callers should represent each hypothesis as a separate belief
- `DECAY_RATE = 0.01` per tick — posterior approaches prior slowly without reinforcement; beliefs aren't erased, they regress to neutral
- Likelihood is clamped to `[0.001, 0.999]` to prevent division by zero and probability collapse
- `batch_bayesian_update` with `likelihoods: {}` is a no-op (returns `{ updated: 0 }`) without error
