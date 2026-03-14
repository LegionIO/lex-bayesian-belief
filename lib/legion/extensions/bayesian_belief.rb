# frozen_string_literal: true

require 'legion/extensions/bayesian_belief/version'
require 'legion/extensions/bayesian_belief/helpers/constants'
require 'legion/extensions/bayesian_belief/helpers/belief'
require 'legion/extensions/bayesian_belief/helpers/belief_network'
require 'legion/extensions/bayesian_belief/runners/bayesian_belief'

module Legion
  module Extensions
    module BayesianBelief
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
    end
  end
end
