module Recommendations
  class AiEmbeddingFilter
    WEIGHTS = {
      completed: 5.0,
      active: 4.0,
      pending: 2.0,
      review_5: 5.0,
      review_4: 3.0,
      wishlist: 3.0,
      cart: 2.0
    }.freeze

    attr_reader :user, :profile_interactions, :excluded_course_ids

    def initialize(user = nil, profile_interactions: nil, excluded_course_ids: [])
      @user = user
      @profile_interactions = profile_interactions
      @excluded_course_ids = Array(excluded_course_ids).map(&:to_i)
    end

    def call(limit: 20)
      profile_vector = build_profile_vector
      return [] if profile_vector.empty?

      excluded_ids = excluded_course_ids | interacted_course_ids | user_excluded_course_ids
      candidate_scores = CourseEmbedding
                         .joins(:course)
                         .where(courses: { status: Course.statuses[:published] })
                         .where.not(course_id: excluded_ids)
                         .pluck(:course_id, :embedding)
                         .filter_map do |course_id, embedding|
        score = VectorMath.cosine_similarity(profile_vector, embedding)
        next if score <= 0.0

        [course_id, score.round(4)]
      end.sort_by { |(_, score)| -score }.take(limit)

      courses_by_id = Course.includes(:category, :creator)
                            .where(id: candidate_scores.map(&:first))
                            .index_by(&:id)

      candidate_scores.filter_map do |course_id, score|
        course = courses_by_id[course_id]
        next unless course

        Recommendations::Result.new(
          course_id: course_id,
          course: course,
          score: score,
          reason_type: "ai_embedding"
        )
      end
    end

    private

    def build_profile_vector
      vectors = interactions.filter_map do |course_id, weight|
        embedding = embedding_map[course_id.to_i]
        next if embedding.blank?

        { vector: embedding, weight: weight }
      end

      VectorMath.weighted_average(vectors)
    end

    def embedding_map
      @embedding_map ||= CourseEmbedding.where(course_id: interacted_course_ids).pluck(:course_id, :embedding).to_h
    end

    def interacted_course_ids
      @interacted_course_ids ||= interactions.keys.map(&:to_i)
    end

    def user_excluded_course_ids
      return [] unless user && profile_interactions.nil?

      InteractionScorer.new(user).interacted_course_ids
    end

    def interactions
      @interactions ||= profile_interactions || user_interactions
    end

    def user_interactions
      return {} unless user

      scores = Hash.new(0.0)

      user.enrollments.find_each do |enrollment|
        key = enrollment.status.to_s
        scores[enrollment.course_id] += WEIGHTS.fetch(key.to_sym, WEIGHTS[:pending])
      end

      user.reviews.where("rating >= ?", 4).find_each do |review|
        scores[review.course_id] += review.rating.to_i >= 5 ? WEIGHTS[:review_5] : WEIGHTS[:review_4]
      end

      user.wishlists.find_each { |wishlist| scores[wishlist.course_id] += WEIGHTS[:wishlist] }
      user.cart&.cart_items&.find_each { |item| scores[item.course_id] += WEIGHTS[:cart] }

      scores
    end
  end
end
