module Recommendations
  class CacheInvalidator
    def self.call(user_id)
      return if user_id.blank?

      UserRecommendation.where(user_id:).delete_all

      RecommendationJob.perform_later(user_id)
    end
  end
end
