# frozen_string_literal: true

RSpec.describe Legion::Extensions::BayesianBelief::Helpers::BeliefNetwork do
  let(:network) { described_class.new }
  let(:consts)  { Legion::Extensions::BayesianBelief::Helpers::Constants }

  def add(content: 'hypothesis', domain: :general, prior: 0.5)
    network.add_belief(content: content, domain: domain, prior: prior)
  end

  describe '#add_belief' do
    it 'adds a belief and returns it' do
      belief = add
      expect(belief).to be_a(Legion::Extensions::BayesianBelief::Helpers::Belief)
      expect(network.count).to eq(1)
    end

    it 'uses provided prior' do
      belief = add(prior: 0.7)
      expect(belief.prior).to eq(0.7)
    end
  end

  describe '#update_belief' do
    it 'updates and returns the belief' do
      belief = add
      result = network.update_belief(belief_id: belief.id, evidence_id: 'ev-1', likelihood: 0.9)
      expect(result).to be_a(Legion::Extensions::BayesianBelief::Helpers::Belief)
      expect(result.posterior).to be > 0.5
    end

    it 'returns nil for unknown belief_id' do
      result = network.update_belief(belief_id: 'nonexistent', evidence_id: 'ev-1', likelihood: 0.8)
      expect(result).to be_nil
    end
  end

  describe '#batch_update' do
    it 'updates multiple beliefs with same evidence' do
      b1 = add(content: 'h1', domain: :test)
      b2 = add(content: 'h2', domain: :test)
      likelihoods = { b1.id => 0.8, b2.id => 0.3 }

      result = network.batch_update(evidence_id: 'ev-batch', likelihoods: likelihoods)
      expect(result.size).to eq(2)
    end

    it 'returns empty hash for empty likelihoods' do
      result = network.batch_update(evidence_id: 'ev-1', likelihoods: {})
      expect(result).to be_empty
    end
  end

  describe '#most_probable' do
    it 'returns beliefs sorted by posterior descending' do
      add(content: 'low',  domain: :test, prior: 0.2)
      add(content: 'high', domain: :test, prior: 0.8)
      add(content: 'mid',  domain: :test, prior: 0.5)

      beliefs = network.most_probable
      expect(beliefs.first.posterior).to be >= beliefs.last.posterior
    end

    it 'limits results' do
      3.times { |idx| add(content: "h#{idx}", domain: :test) }
      expect(network.most_probable(limit: 2).size).to eq(2)
    end

    it 'filters by domain' do
      add(content: 'a', domain: :alpha)
      add(content: 'b', domain: :beta)
      results = network.most_probable(domain: :alpha)
      expect(results.all? { |b| b.domain == :alpha }).to be true
    end
  end

  describe '#least_probable' do
    it 'returns beliefs sorted by posterior ascending' do
      add(content: 'low',  domain: :test, prior: 0.1)
      add(content: 'high', domain: :test, prior: 0.9)

      beliefs = network.least_probable
      expect(beliefs.first.posterior).to be <= beliefs.last.posterior
    end
  end

  describe '#by_domain' do
    it 'returns only beliefs in specified domain' do
      add(content: 'a', domain: :alpha)
      add(content: 'b', domain: :beta)
      result = network.by_domain(domain: :alpha)
      expect(result.size).to eq(1)
      expect(result.first.domain).to eq(:alpha)
    end
  end

  describe '#posterior_distribution' do
    it 'returns normalized probabilities that sum to ~1' do
      add(content: 'h1', domain: :test, prior: 0.3)
      add(content: 'h2', domain: :test, prior: 0.7)

      dist = network.posterior_distribution(domain: :test)
      expect(dist.values.sum).to be_within(0.001).of(1.0)
    end

    it 'returns empty hash when no beliefs exist' do
      expect(network.posterior_distribution).to eq({})
    end
  end

  describe '#information_gain' do
    it 'returns a non-negative float' do
      belief = add
      gain = network.information_gain(belief_id: belief.id, evidence_id: 'ev-1', likelihood: 0.9)
      expect(gain).to be >= 0.0
    end

    it 'returns 0.0 for unknown belief' do
      gain = network.information_gain(belief_id: 'nonexistent', evidence_id: 'ev-1', likelihood: 0.8)
      expect(gain).to eq(0.0)
    end

    it 'does not mutate the belief posterior' do
      belief = add
      before = belief.posterior
      network.information_gain(belief_id: belief.id, evidence_id: 'ev-1', likelihood: 0.9)
      expect(belief.posterior).to eq(before)
    end

    it 'returns higher gain for more extreme likelihoods' do
      b1 = add(content: 'h1')
      b2 = add(content: 'h2')

      gain_strong = network.information_gain(belief_id: b1.id, evidence_id: 'ev', likelihood: 0.95)
      gain_weak   = network.information_gain(belief_id: b2.id, evidence_id: 'ev', likelihood: 0.55)
      expect(gain_strong).to be > gain_weak
    end
  end

  describe '#entropy' do
    it 'returns 0.0 when no beliefs' do
      expect(network.entropy).to eq(0.0)
    end

    it 'returns a positive float when beliefs exist' do
      2.times { |idx| add(content: "h#{idx}") }
      expect(network.entropy).to be > 0.0
    end
  end

  describe '#decay_all' do
    it 'returns count of beliefs updated' do
      3.times { |idx| add(content: "h#{idx}") }
      expect(network.decay_all).to eq(3)
    end

    it 'drifts posterior toward prior' do
      belief = add(prior: 0.5)
      belief.update(likelihood: 0.9, evidence_id: 'ev-1')
      before = belief.posterior

      network.decay_all

      after = belief.posterior
      expect(after).to be < before
    end
  end

  describe '#to_h' do
    it 'includes belief_count and beliefs keys' do
      add
      hash = network.to_h
      expect(hash).to have_key(:belief_count)
      expect(hash).to have_key(:beliefs)
      expect(hash[:belief_count]).to eq(1)
    end
  end
end
