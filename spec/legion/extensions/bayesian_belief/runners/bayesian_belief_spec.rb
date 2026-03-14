# frozen_string_literal: true

require 'legion/extensions/bayesian_belief/client'

RSpec.describe Legion::Extensions::BayesianBelief::Runners::BayesianBelief do
  let(:client) { Legion::Extensions::BayesianBelief::Client.new }

  describe '#add_bayesian_belief' do
    it 'adds a belief and returns success' do
      result = client.add_bayesian_belief(content: 'test hypothesis', domain: :general)
      expect(result[:success]).to be true
      expect(result[:belief_id]).to match(/\A[0-9a-f-]{36}\z/)
      expect(result[:domain]).to eq(:general)
    end

    it 'uses default prior when none provided' do
      result = client.add_bayesian_belief(content: 'test', domain: :test)
      expect(result[:prior]).to eq(Legion::Extensions::BayesianBelief::Helpers::Constants::DEFAULT_PRIOR)
    end

    it 'uses provided prior' do
      result = client.add_bayesian_belief(content: 'test', domain: :test, prior: 0.7)
      expect(result[:prior]).to be_within(0.001).of(0.7)
    end
  end

  describe '#update_bayesian_belief' do
    it 'updates an existing belief' do
      added  = client.add_bayesian_belief(content: 'h1', domain: :test)
      result = client.update_bayesian_belief(
        belief_id:   added[:belief_id],
        evidence_id: 'ev-1',
        likelihood:  0.9
      )
      expect(result[:success]).to be true
      expect(result[:posterior]).to be > 0.5
      expect(result[:update_count]).to eq(1)
    end

    it 'returns not_found for unknown belief' do
      result = client.update_bayesian_belief(belief_id: 'nonexistent', evidence_id: 'ev-1', likelihood: 0.8)
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:not_found)
    end

    it 'returns confidence_label' do
      added  = client.add_bayesian_belief(content: 'h1', domain: :test, prior: 0.95)
      result = client.update_bayesian_belief(
        belief_id:   added[:belief_id],
        evidence_id: 'ev-1',
        likelihood:  0.9
      )
      expect(result[:confidence_label]).to eq(:certain)
    end
  end

  describe '#batch_bayesian_update' do
    it 'updates multiple beliefs' do
      b1 = client.add_bayesian_belief(content: 'h1', domain: :test)
      b2 = client.add_bayesian_belief(content: 'h2', domain: :test)
      likelihoods = { b1[:belief_id] => 0.8, b2[:belief_id] => 0.3 }

      result = client.batch_bayesian_update(evidence_id: 'ev-batch', likelihoods: likelihoods)
      expect(result[:success]).to be true
      expect(result[:updated]).to eq(2)
    end

    it 'handles empty likelihoods gracefully' do
      result = client.batch_bayesian_update(evidence_id: 'ev-1', likelihoods: {})
      expect(result[:success]).to be true
      expect(result[:updated]).to eq(0)
    end
  end

  describe '#most_probable_beliefs' do
    it 'returns beliefs sorted by probability' do
      client.add_bayesian_belief(content: 'low',  domain: :ranked, prior: 0.2)
      client.add_bayesian_belief(content: 'high', domain: :ranked, prior: 0.8)

      result = client.most_probable_beliefs(domain: :ranked)
      expect(result[:success]).to be true
      expect(result[:beliefs].first[:posterior]).to be >= result[:beliefs].last[:posterior]
    end

    it 'respects limit parameter' do
      5.times { |idx| client.add_bayesian_belief(content: "h#{idx}", domain: :limit_test) }
      result = client.most_probable_beliefs(domain: :limit_test, limit: 3)
      expect(result[:count]).to eq(3)
    end
  end

  describe '#least_probable_beliefs' do
    it 'returns beliefs sorted by ascending probability' do
      client.add_bayesian_belief(content: 'low',  domain: :sorted, prior: 0.1)
      client.add_bayesian_belief(content: 'high', domain: :sorted, prior: 0.9)

      result = client.least_probable_beliefs(domain: :sorted)
      expect(result[:beliefs].first[:posterior]).to be <= result[:beliefs].last[:posterior]
    end
  end

  describe '#posterior_distribution' do
    it 'returns normalized distribution summing to 1' do
      client.add_bayesian_belief(content: 'h1', domain: :dist, prior: 0.3)
      client.add_bayesian_belief(content: 'h2', domain: :dist, prior: 0.7)

      result = client.posterior_distribution(domain: :dist)
      expect(result[:success]).to be true
      expect(result[:distribution].values.sum).to be_within(0.001).of(1.0)
    end

    it 'returns empty distribution when no beliefs' do
      result = client.posterior_distribution(domain: :empty_domain)
      expect(result[:distribution]).to be_empty
    end
  end

  describe '#information_gain' do
    it 'computes gain without mutating the belief' do
      added   = client.add_bayesian_belief(content: 'h1', domain: :ig)
      before  = added[:posterior]
      result  = client.information_gain(belief_id: added[:belief_id], evidence_id: 'ev-1', likelihood: 0.9)
      expect(result[:success]).to be true
      expect(result[:information_gain]).to be >= 0.0

      check = client.most_probable_beliefs(domain: :ig)
      expect(check[:beliefs].first[:posterior]).to be_within(0.001).of(before)
    end
  end

  describe '#belief_entropy' do
    it 'returns entropy for all beliefs' do
      client.add_bayesian_belief(content: 'h1', domain: :ent)
      client.add_bayesian_belief(content: 'h2', domain: :ent)

      result = client.belief_entropy(domain: :ent)
      expect(result[:success]).to be true
      expect(result[:entropy]).to be >= 0.0
    end

    it 'returns 0.0 entropy when no beliefs exist' do
      fresh = Legion::Extensions::BayesianBelief::Client.new
      result = fresh.belief_entropy
      expect(result[:entropy]).to eq(0.0)
    end
  end

  describe '#update_bayesian_beliefs (decay)' do
    it 'returns success and decayed count' do
      2.times { |idx| client.add_bayesian_belief(content: "h#{idx}", domain: :decay) }
      result = client.update_bayesian_beliefs
      expect(result[:success]).to be true
      expect(result[:decayed]).to eq(2)
    end
  end

  describe '#bayesian_belief_stats' do
    it 'returns stats hash with expected keys' do
      client.add_bayesian_belief(content: 'h1', domain: :stats)
      result = client.bayesian_belief_stats
      expect(result[:success]).to be true
      expect(result).to have_key(:total_beliefs)
      expect(result).to have_key(:entropy)
      expect(result).to have_key(:most_probable)
      expect(result).to have_key(:least_probable)
      expect(result).to have_key(:capacity)
    end

    it 'returns nil for most/least probable when no beliefs' do
      fresh  = Legion::Extensions::BayesianBelief::Client.new
      result = fresh.bayesian_belief_stats
      expect(result[:most_probable]).to be_nil
      expect(result[:least_probable]).to be_nil
    end
  end
end
