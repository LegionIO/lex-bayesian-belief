# frozen_string_literal: true

module Legion
  module Extensions
    module BayesianBelief
      module Helpers
        class BeliefNetwork
          include Constants

          attr_reader :beliefs

          def initialize
            @beliefs = {}
          end

          def add_belief(content:, domain:, prior: Constants::DEFAULT_PRIOR)
            return nil if @beliefs.size >= Constants::MAX_HYPOTHESES

            belief = Belief.new(content: content, domain: domain, prior: prior)
            @beliefs[belief.id] = belief
            belief
          end

          def update_belief(belief_id:, evidence_id:, likelihood:)
            belief = @beliefs[belief_id]
            return nil unless belief

            belief.update(likelihood: likelihood, evidence_id: evidence_id)
            belief
          end

          def batch_update(evidence_id:, likelihoods:)
            return {} if likelihoods.empty?

            updated = {}
            likelihoods.each do |belief_id, likelihood|
              belief = update_belief(belief_id: belief_id, evidence_id: evidence_id, likelihood: likelihood)
              updated[belief_id] = belief.posterior if belief
            end

            normalize_posteriors(updated.keys)
            updated
          end

          def most_probable(domain: nil, limit: 5)
            filtered(domain).sort_by { |b| -b.posterior }.first(limit)
          end

          def least_probable(domain: nil, limit: 5)
            filtered(domain).sort_by(&:posterior).first(limit)
          end

          def by_domain(domain:)
            @beliefs.values.select { |b| b.domain == domain }
          end

          def posterior_distribution(domain: nil)
            subset = filtered(domain)
            total  = subset.sum(&:posterior)
            return {} if total.zero?

            subset.to_h { |b| [b.id, b.posterior / total] }
          end

          def information_gain(belief_id:, evidence_id:, likelihood:) # rubocop:disable Lint/UnusedMethodArgument
            belief = @beliefs[belief_id]
            return 0.0 unless belief

            prior_p = belief.posterior
            clamped = likelihood.clamp(Constants::LIKELIHOOD_FLOOR, Constants::LIKELIHOOD_CEILING)
            marginal = (clamped * prior_p) + ((1.0 - clamped) * (1.0 - prior_p))
            post_p = (clamped * prior_p) / marginal
            post_p = post_p.clamp(Constants::PRIOR_FLOOR, Constants::PRIOR_CEILING)

            kl_divergence(prior_p, post_p)
          end

          def entropy(domain: nil)
            dist = posterior_distribution(domain: domain)
            return 0.0 if dist.empty?

            -dist.values.sum do |prob|
              next 0.0 if prob <= 0.0

              prob * Math.log2(prob)
            end
          end

          def decay_all
            @beliefs.each_value do |belief|
              shift = (belief.posterior - belief.prior) * Constants::DECAY_RATE
              new_posterior = belief.posterior - shift
              belief.instance_variable_set(:@posterior, new_posterior.clamp(Constants::PRIOR_FLOOR, Constants::PRIOR_CEILING))
              belief.instance_variable_set(:@last_updated_at, Time.now.utc)
            end
            @beliefs.size
          end

          def count
            @beliefs.size
          end

          def to_h
            {
              belief_count: @beliefs.size,
              beliefs:      @beliefs.transform_values(&:to_h)
            }
          end

          private

          def filtered(domain)
            return @beliefs.values if domain.nil?

            by_domain(domain: domain)
          end

          def normalize_posteriors(belief_ids)
            subset = belief_ids.filter_map { |bid| @beliefs[bid] }
            total  = subset.sum(&:posterior)
            return if total.zero?

            subset.each do |belief|
              normalized = (belief.posterior / total).clamp(Constants::PRIOR_FLOOR, Constants::PRIOR_CEILING)
              belief.instance_variable_set(:@posterior, normalized)
            end
          end

          def kl_divergence(prior_p, post_p)
            return 0.0 if prior_p <= 0.0 || post_p <= 0.0

            prior_q = 1.0 - prior_p
            post_q  = 1.0 - post_p

            term1 = post_p  * Math.log2(post_p  / prior_p)
            term2 = post_q  * Math.log2(post_q  / prior_q)
            term1 + term2
          end
        end
      end
    end
  end
end
