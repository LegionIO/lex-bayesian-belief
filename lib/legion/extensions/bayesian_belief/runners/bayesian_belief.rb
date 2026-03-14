# frozen_string_literal: true

module Legion
  module Extensions
    module BayesianBelief
      module Runners
        module BayesianBelief
          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)

          def add_bayesian_belief(content:, domain:, prior: nil, **)
            pri = (prior || Helpers::Constants::DEFAULT_PRIOR).clamp(
              Helpers::Constants::PRIOR_FLOOR,
              Helpers::Constants::PRIOR_CEILING
            )
            belief = belief_network.add_belief(content: content, domain: domain, prior: pri)
            unless belief
              Legion::Logging.warn "[bayesian_belief] add failed: network at capacity (#{Helpers::Constants::MAX_HYPOTHESES})"
              return { success: false, reason: :capacity_exceeded, max: Helpers::Constants::MAX_HYPOTHESES }
            end

            Legion::Logging.debug "[bayesian_belief] add: id=#{belief.id[0..7]} domain=#{domain} prior=#{pri.round(3)}"
            { success: true, belief_id: belief.id, domain: domain, prior: belief.prior, posterior: belief.posterior }
          end

          def update_bayesian_belief(belief_id:, evidence_id:, likelihood:, **)
            clamped = likelihood.clamp(Helpers::Constants::LIKELIHOOD_FLOOR, Helpers::Constants::LIKELIHOOD_CEILING)
            belief  = belief_network.update_belief(belief_id: belief_id, evidence_id: evidence_id, likelihood: clamped)
            unless belief
              Legion::Logging.debug "[bayesian_belief] update failed: belief_id=#{belief_id} not found"
              return { success: false, reason: :not_found, belief_id: belief_id }
            end

            Legion::Logging.debug "[bayesian_belief] update: id=#{belief_id[0..7]} evidence=#{evidence_id} " \
                                  "likelihood=#{clamped.round(3)} posterior=#{belief.posterior.round(3)}"
            {
              success:          true,
              belief_id:        belief_id,
              evidence_id:      evidence_id,
              likelihood:       clamped,
              posterior:        belief.posterior,
              confidence_label: belief.confidence_label,
              update_count:     belief.update_count
            }
          end

          def batch_bayesian_update(evidence_id:, likelihoods:, **)
            if likelihoods.nil? || likelihoods.empty?
              Legion::Logging.debug '[bayesian_belief] batch_update: empty likelihoods, skipping'
              return { success: true, updated: 0, posteriors: {} }
            end

            posteriors = belief_network.batch_update(evidence_id: evidence_id, likelihoods: likelihoods)
            Legion::Logging.debug "[bayesian_belief] batch_update: evidence=#{evidence_id} updated=#{posteriors.size}"
            { success: true, evidence_id: evidence_id, updated: posteriors.size, posteriors: posteriors }
          end

          def most_probable_beliefs(domain: nil, limit: 5, **)
            beliefs = belief_network.most_probable(domain: domain, limit: limit)
            Legion::Logging.debug "[bayesian_belief] most_probable: domain=#{domain.inspect} count=#{beliefs.size}"
            { success: true, beliefs: beliefs.map(&:to_h), count: beliefs.size }
          end

          def least_probable_beliefs(domain: nil, limit: 5, **)
            beliefs = belief_network.least_probable(domain: domain, limit: limit)
            Legion::Logging.debug "[bayesian_belief] least_probable: domain=#{domain.inspect} count=#{beliefs.size}"
            { success: true, beliefs: beliefs.map(&:to_h), count: beliefs.size }
          end

          def posterior_distribution(domain: nil, **)
            dist = belief_network.posterior_distribution(domain: domain)
            Legion::Logging.debug "[bayesian_belief] posterior_distribution: domain=#{domain.inspect} size=#{dist.size}"
            { success: true, distribution: dist, size: dist.size }
          end

          def information_gain(belief_id:, evidence_id:, likelihood:, **)
            clamped = likelihood.clamp(Helpers::Constants::LIKELIHOOD_FLOOR, Helpers::Constants::LIKELIHOOD_CEILING)
            gain    = belief_network.information_gain(belief_id: belief_id, evidence_id: evidence_id, likelihood: clamped)
            Legion::Logging.debug "[bayesian_belief] information_gain: id=#{belief_id[0..7]} likelihood=#{clamped.round(3)} gain=#{gain.round(4)}"
            { success: true, belief_id: belief_id, evidence_id: evidence_id, likelihood: clamped, information_gain: gain }
          end

          def belief_entropy(domain: nil, **)
            ent = belief_network.entropy(domain: domain)
            Legion::Logging.debug "[bayesian_belief] entropy: domain=#{domain.inspect} entropy=#{ent.round(4)}"
            { success: true, domain: domain, entropy: ent }
          end

          def update_bayesian_beliefs(**)
            decayed = belief_network.decay_all
            Legion::Logging.debug "[bayesian_belief] decay cycle: beliefs_updated=#{decayed}"
            { success: true, decayed: decayed }
          end

          def bayesian_belief_stats(**)
            total = belief_network.count
            ent   = belief_network.entropy
            most  = belief_network.most_probable(limit: 1).first
            least = belief_network.least_probable(limit: 1).first

            Legion::Logging.debug "[bayesian_belief] stats: total=#{total} entropy=#{ent.round(4)}"
            {
              success:        true,
              total_beliefs:  total,
              entropy:        ent,
              most_probable:  most&.to_h,
              least_probable: least&.to_h,
              capacity:       Helpers::Constants::MAX_HYPOTHESES
            }
          end

          private

          def belief_network
            @belief_network ||= Helpers::BeliefNetwork.new
          end
        end
      end
    end
  end
end
