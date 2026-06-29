module Recommendations
  # Orchestrator — chi duoc goi tu RecommendationJob.
  # Khong bao gio duoc goi tu Controller.
  class Computer
    attr_reader :user

    def initialize(user)
      @user = user
      @interaction_scorer = InteractionScorer.new(user)
    end

    def call(limit: 20)
      w = @interaction_scorer.weights

      if w[:alpha].zero? && w[:beta].zero?
        # Cold start: chi dung popularity
        PopularityScorer.new(exclude_enrolled_for: user).call(limit: limit)
      else
        cf_results = CollaborativeFilter.new(
          user, interaction_scorer: @interaction_scorer
        ).call(limit: limit)
        content_results = ContentFilter.new(
          user, interaction_scorer: @interaction_scorer
        ).call(limit: limit)
        pop_results     = PopularityScorer.new(exclude_enrolled_for: user).call(limit: limit)

        ScoreFuser.new(
          cf_results: cf_results,
          content_results: content_results,
          popular_results: pop_results
        ).fuse(alpha: w[:alpha], beta: w[:beta], gamma: w[:gamma], limit: limit)
      end
    end
  end
end
