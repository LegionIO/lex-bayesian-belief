# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module BayesianBelief
      module Helpers
        class Belief
          include Constants

          attr_reader :id, :content, :domain, :prior, :posterior,
                      :evidence_history, :update_count, :created_at, :last_updated_at

          def initialize(content:, domain:, prior: Constants::DEFAULT_PRIOR)
            @id               = SecureRandom.uuid
            @content          = content
            @domain           = domain
            @prior            = prior.clamp(Constants::PRIOR_FLOOR, Constants::PRIOR_CEILING)
            @posterior        = @prior
            @evidence_history = []
            @update_count     = 0
            @created_at       = Time.now.utc
            @last_updated_at  = @created_at
          end

          def update(likelihood:, evidence_id:)
            clamped_likelihood = likelihood.clamp(Constants::LIKELIHOOD_FLOOR, Constants::LIKELIHOOD_CEILING)
            marginal = (clamped_likelihood * @posterior) + ((1.0 - clamped_likelihood) * (1.0 - @posterior))
            new_posterior = (clamped_likelihood * @posterior) / marginal
            @posterior = new_posterior.clamp(Constants::PRIOR_FLOOR, Constants::PRIOR_CEILING)
            @update_count    += 1
            @last_updated_at  = Time.now.utc

            @evidence_history << {
              evidence_id:     evidence_id,
              likelihood:      clamped_likelihood,
              posterior_after: @posterior
            }
            @evidence_history.shift while @evidence_history.size > Constants::MAX_HISTORY

            @posterior
          end

          def log_odds
            Math.log(@posterior / (1.0 - @posterior))
          end

          def confidence_label
            Constants::CONFIDENCE_LABELS.each do |range, label|
              return label if range.cover?(@posterior)
            end
            :unknown
          end

          def surprise(observation_likelihood:)
            clamped = observation_likelihood.clamp(Constants::LIKELIHOOD_FLOOR, 1.0)
            -Math.log2(clamped)
          end

          def reset_to_prior!
            @posterior       = @prior
            @update_count    = 0
            @evidence_history = []
            @last_updated_at  = Time.now.utc
            @posterior
          end

          def stale?(threshold: Constants::STALE_THRESHOLD)
            (Time.now.utc - @last_updated_at) > threshold
          end

          def to_h
            {
              id:               @id,
              content:          @content,
              domain:           @domain,
              prior:            @prior,
              posterior:        @posterior,
              confidence_label: confidence_label,
              log_odds:         log_odds,
              update_count:     @update_count,
              evidence_history: @evidence_history,
              created_at:       @created_at,
              last_updated_at:  @last_updated_at
            }
          end
        end
      end
    end
  end
end
