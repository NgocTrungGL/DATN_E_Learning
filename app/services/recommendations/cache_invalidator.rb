module Recommendations
  class CacheInvalidator
    STALE_TIME = 25.hours.ago

    def self.call(user_id)
      return if user_id.blank?

      UserRecommendation
        .where(user_id:)
        .update_all(computed_at: STALE_TIME, updated_at: Time.current)

      RecommendationJob.perform_later(user_id)
    end
  end
end
