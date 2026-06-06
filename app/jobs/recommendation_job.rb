class RecommendationJob < ApplicationJob
  queue_as :low

  def perform(user_id)
    user = User.find_by(id: user_id)
    return unless user

    results = Recommendations::Computer.new(user).call(limit: 20)
    return if results.empty?

    now = Time.current
    rows = results.map do |r|
      {
        user_id: user.id,
        course_id: r.course_id,
        score: r.score,
        reason_type: r.reason_type,
        computed_at: now,
        created_at: now,
        updated_at: now
      }
    end

    ActiveRecord::Base.transaction do
      UserRecommendation.where(user_id: user.id).delete_all
      UserRecommendation.insert_all(rows)
    end
  end
end
