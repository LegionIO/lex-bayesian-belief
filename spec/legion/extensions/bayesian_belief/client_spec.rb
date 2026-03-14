# frozen_string_literal: true

require 'legion/extensions/bayesian_belief/client'

RSpec.describe Legion::Extensions::BayesianBelief::Client do
  let(:client) { described_class.new }

  it 'responds to all runner methods' do
    expect(client).to respond_to(:add_bayesian_belief)
    expect(client).to respond_to(:update_bayesian_belief)
    expect(client).to respond_to(:batch_bayesian_update)
    expect(client).to respond_to(:most_probable_beliefs)
    expect(client).to respond_to(:least_probable_beliefs)
    expect(client).to respond_to(:posterior_distribution)
    expect(client).to respond_to(:information_gain)
    expect(client).to respond_to(:belief_entropy)
    expect(client).to respond_to(:update_bayesian_beliefs)
    expect(client).to respond_to(:bayesian_belief_stats)
  end
end
