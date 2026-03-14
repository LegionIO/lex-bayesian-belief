# frozen_string_literal: true

require 'legion/extensions/bayesian_belief/helpers/constants'
require 'legion/extensions/bayesian_belief/helpers/belief'
require 'legion/extensions/bayesian_belief/helpers/belief_network'
require 'legion/extensions/bayesian_belief/runners/bayesian_belief'

module Legion
  module Extensions
    module BayesianBelief
      class Client
        include Runners::BayesianBelief

        def initialize(**)
          @belief_network = Helpers::BeliefNetwork.new
        end

        private

        attr_reader :belief_network
      end
    end
  end
end
