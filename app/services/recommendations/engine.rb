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

      if personalization_signal?
        results = compute_and_cache_recommendations(limit)
        return results.first(limit) if results.any?
      end

      # Stale or empty -> enqueue async recompute + return popularity fallback
      RecommendationJob.perform_later(@user.id) unless @user.nil?
      excluded_ids = InteractionScorer.new(@user).interacted_course_ids
      PopularityScorer.new(exclude_course_ids: excluded_ids).call(limit: limit)
    end

    private

    def fetch_fresh_recommendations(limit)
      excluded_ids = InteractionScorer.new(@user).interacted_course_ids

      UserRecommendation
        .where(user_id: @user.id)
        .where.not(course_id: excluded_ids)
        .fresh
        .by_score
        .includes(course: [:category, :creator])
        .limit(limit + excluded_ids.size)
        .map do |rec|
          next unless rec.course&.published?

          Recommendations::Result.new(
            course_id: rec.course_id,
            course: rec.course,
            score: rec.score,
            reason_type: rec.reason_type
          )
        end.compact.first(limit)
    end

    def personalization_signal?
      return false unless @user

      @user.enrollments.exists? ||
        @user.wishlists.exists? ||
        @user.reviews.exists? ||
        @user.cart&.cart_items&.exists? ||
        @user.progress_trackings.exists?
    end

    def compute_and_cache_recommendations(limit)
      results = Computer.new(@user).call(limit: [limit, 20].max)
      return [] if results.empty?

      now = Time.current
      rows = results.map do |result|
        {
          user_id: @user.id,
          course_id: result.course_id,
          score: result.score,
          reason_type: result.reason_type,
          computed_at: now,
          created_at: now,
          updated_at: now
        }
      end

      ActiveRecord::Base.transaction do
        UserRecommendation.where(user_id: @user.id).delete_all
        UserRecommendation.insert_all(rows)
      end

      results
    end
  end
end
