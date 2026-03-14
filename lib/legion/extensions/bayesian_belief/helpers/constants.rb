# frozen_string_literal: true

module Legion
  module Extensions
    module BayesianBelief
      module Helpers
        module Constants
          MAX_HYPOTHESES  = 200
          MAX_EVIDENCE    = 500
          MAX_HISTORY     = 300

          DEFAULT_PRIOR     = 0.5
          PRIOR_FLOOR       = 0.001
          PRIOR_CEILING     = 0.999
          LIKELIHOOD_FLOOR  = 0.001
          LIKELIHOOD_CEILING = 0.999

          DECAY_RATE       = 0.01
          STALE_THRESHOLD  = 120

          CONFIDENCE_LABELS = {
            (0.9..)     => :certain,
            (0.7...0.9) => :confident,
            (0.5...0.7) => :leaning,
            (0.3...0.5) => :uncertain,
            (..0.3)     => :doubtful
          }.freeze
        end
      end
    end
  end
end
