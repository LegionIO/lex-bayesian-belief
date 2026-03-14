# frozen_string_literal: true

RSpec.describe Legion::Extensions::BayesianBelief::Helpers::Belief do
  let(:belief) { described_class.new(content: 'test hypothesis', domain: :general) }

  describe '#initialize' do
    it 'sets prior and posterior to default' do
      expect(belief.prior).to eq(Legion::Extensions::BayesianBelief::Helpers::Constants::DEFAULT_PRIOR)
      expect(belief.posterior).to eq(belief.prior)
    end

    it 'generates a uuid id' do
      expect(belief.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'starts with empty evidence_history' do
      expect(belief.evidence_history).to be_empty
    end

    it 'clamps prior to floor/ceiling' do
      high = described_class.new(content: 'test', domain: :x, prior: 1.5)
      low  = described_class.new(content: 'test', domain: :x, prior: -0.1)
      expect(high.prior).to eq(Legion::Extensions::BayesianBelief::Helpers::Constants::PRIOR_CEILING)
      expect(low.prior).to eq(Legion::Extensions::BayesianBelief::Helpers::Constants::PRIOR_FLOOR)
    end
  end

  describe '#update' do
    it 'raises posterior when likelihood is high' do
      before = belief.posterior
      belief.update(likelihood: 0.9, evidence_id: 'ev-1')
      expect(belief.posterior).to be > before
    end

    it 'lowers posterior when likelihood is low' do
      before = belief.posterior
      belief.update(likelihood: 0.1, evidence_id: 'ev-1')
      expect(belief.posterior).to be < before
    end

    it 'records evidence in history' do
      belief.update(likelihood: 0.8, evidence_id: 'ev-1')
      expect(belief.evidence_history.size).to eq(1)
      expect(belief.evidence_history.first[:evidence_id]).to eq('ev-1')
    end

    it 'increments update_count' do
      belief.update(likelihood: 0.7, evidence_id: 'ev-1')
      belief.update(likelihood: 0.6, evidence_id: 'ev-2')
      expect(belief.update_count).to eq(2)
    end

    it 'clamps posterior within bounds' do
      10.times { |idx| belief.update(likelihood: 0.999, evidence_id: "ev-#{idx}") }
      expect(belief.posterior).to be <= Legion::Extensions::BayesianBelief::Helpers::Constants::PRIOR_CEILING
      expect(belief.posterior).to be >= Legion::Extensions::BayesianBelief::Helpers::Constants::PRIOR_FLOOR
    end
  end

  describe '#log_odds' do
    it 'returns 0.0 at prior 0.5' do
      expect(belief.log_odds).to be_within(0.001).of(0.0)
    end

    it 'returns positive value when posterior > 0.5' do
      belief.update(likelihood: 0.9, evidence_id: 'ev-1')
      expect(belief.log_odds).to be > 0.0
    end

    it 'returns negative value when posterior < 0.5' do
      belief.update(likelihood: 0.1, evidence_id: 'ev-1')
      expect(belief.log_odds).to be < 0.0
    end
  end

  describe '#confidence_label' do
    it 'returns :leaning for default prior 0.5' do
      expect(belief.confidence_label).to eq(:leaning)
    end

    it 'returns :certain for high posterior' do
      high = described_class.new(content: 'test', domain: :x, prior: 0.95)
      expect(high.confidence_label).to eq(:certain)
    end

    it 'returns :doubtful for low posterior' do
      low = described_class.new(content: 'test', domain: :x, prior: 0.1)
      expect(low.confidence_label).to eq(:doubtful)
    end

    it 'returns :confident for posterior in 0.7..0.9' do
      conf = described_class.new(content: 'test', domain: :x, prior: 0.8)
      expect(conf.confidence_label).to eq(:confident)
    end

    it 'returns :uncertain for posterior in 0.3..0.5' do
      unc = described_class.new(content: 'test', domain: :x, prior: 0.4)
      expect(unc.confidence_label).to eq(:uncertain)
    end
  end

  describe '#surprise' do
    it 'returns 0.0 for certain observation (likelihood 1.0)' do
      expect(belief.surprise(observation_likelihood: 1.0)).to be_within(0.001).of(0.0)
    end

    it 'returns positive surprise for unlikely observation' do
      expect(belief.surprise(observation_likelihood: 0.125)).to be_within(0.001).of(3.0)
    end
  end

  describe '#reset_to_prior!' do
    it 'resets posterior to original prior' do
      belief.update(likelihood: 0.9, evidence_id: 'ev-1')
      expect(belief.posterior).not_to eq(belief.prior)
      belief.reset_to_prior!
      expect(belief.posterior).to eq(belief.prior)
    end

    it 'clears evidence history and update count' do
      belief.update(likelihood: 0.8, evidence_id: 'ev-1')
      belief.reset_to_prior!
      expect(belief.evidence_history).to be_empty
      expect(belief.update_count).to eq(0)
    end
  end

  describe '#to_h' do
    it 'includes all required keys' do
      hash = belief.to_h
      %i[id content domain prior posterior confidence_label log_odds update_count
         evidence_history created_at last_updated_at].each do |key|
        expect(hash).to have_key(key)
      end
    end
  end
end
