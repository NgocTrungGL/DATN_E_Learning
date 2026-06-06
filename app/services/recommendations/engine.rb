module Recommendations
  # Cua vao cho Controller. Chi doc pre-computed, fallback ve popularity.
  class Engine
    attr_reader :user

    def initialize(user)
      @user = user
    end

    def call(limit: 10)
      results = fetch_fresh_recommendations(limit)
      return results if results.any?

      # Stale or empty → enqueue async recompute + return popularity fallback
      RecommendationJob.perform_later(@user.id) unless @user.nil?
      PopularityScorer.new(exclude_enrolled_for: @user).call(limit: limit)
    end

    private

    def fetch_fresh_recommendations(limit)
      UserRecommendation
        .where(user_id: @user.id)
        .fresh
        .by_score
        .includes(course: [:category, :instructor])
        .limit(limit)
        .map do |rec|
          next unless rec.course&.published?

          Recommendations::Result.new(
            course_id: rec.course_id,
            course: rec.course,
            score: rec.score,
            reason_type: rec.reason_type
          )
        end.compact
    end
  end
end
