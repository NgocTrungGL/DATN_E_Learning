module Recommendations
  class ProfileHybridFilter
    attr_reader :profile_interactions, :excluded_course_ids

    def initialize(profile_interactions:, excluded_course_ids: [])
      @profile_interactions = profile_interactions
      @excluded_course_ids = Array(excluded_course_ids).map(&:to_i)
    end

    def call(limit: 20)
      return [] if profile_interactions.blank?

      ScoreFuser.new(
        cf_results: collaborative_results(limit: limit * 3),
        content_results: content_results(limit: limit * 3),
        popular_results: popular_results(limit: limit * 3)
      ).fuse(**weights, limit: limit)
    end

    private

    def source_course_ids
      @source_course_ids ||= profile_interactions.keys.map(&:to_i)
    end

    def excluded_ids
      @excluded_ids ||= (source_course_ids | excluded_course_ids)
    end

    def weights
      count = profile_interactions.size
      return { alpha: 0.50, beta: 0.35, gamma: 0.15 } if count >= 5
      return { alpha: 0.20, beta: 0.50, gamma: 0.30 } if count >= 2

      { alpha: 0.00, beta: 0.30, gamma: 0.70 }
    end

    def collaborative_results(limit:)
      similar_ids = CourseSimilarity
                    .where(course_a_id: source_course_ids)
                    .where("score > 0.05")
                    .order(score: :desc)
                    .pluck(:course_b_id)
                    .uniq - excluded_ids

      return [] if similar_ids.empty?

      sim_scores = CourseSimilarity
                   .where(course_a_id: source_course_ids, course_b_id: similar_ids)
                   .group(:course_b_id)
                   .maximum(:score)

      courses = Course.published.where(id: similar_ids).includes(:category, :creator).index_by(&:id)

      sim_scores.filter_map do |course_id, score|
        course = courses[course_id]
        next unless course

        Recommendations::Result.new(course_id: course_id, course: course, score: score.to_f, reason_type: "cf")
      end.sort_by { |result| -result.score }.take(limit)
    end

    def content_results(limit:)
      category_ids = Course.where(id: source_course_ids).where.not(category_id: nil).distinct.pluck(:category_id)
      return [] if category_ids.empty?

      parent_ids = Category.where(id: category_ids).where.not(parent_id: nil).pluck(:parent_id)
      target_category_ids = (category_ids | parent_ids).compact

      Course.published
            .where(category_id: target_category_ids)
            .where.not(id: excluded_ids)
            .includes(:category, :creator)
            .limit(limit * 2)
            .map do |course|
              score = category_ids.include?(course.category_id) ? 1.0 : 0.5
              Recommendations::Result.new(course_id: course.id, course: course, score: score, reason_type: "content")
            end
            .sort_by { |result| -result.score }
            .take(limit)
    end

    def popular_results(limit:)
      Course.published
            .where.not(id: excluded_ids)
            .left_joins(:reviews, :enrollments)
            .group("courses.id")
            .select(
              "courses.*",
              "COUNT(DISTINCT reviews.id) AS review_count",
              "AVG(reviews.rating) AS avg_rating",
              "COUNT(DISTINCT enrollments.id) AS enrollment_count"
            )
            .map do |course|
              n = course.review_count.to_i
              avg = course.avg_rating.to_f
              global_mean = Review.average(:rating).to_f.nonzero? || 3.5
              bayesian = (PopularityScorer::C * global_mean + n * avg) / (PopularityScorer::C + n)
              volume_norm = Math.log10(course.enrollment_count.to_i + 1) / 5.0
              score = (0.7 * (bayesian / 5.0) + 0.3 * volume_norm).round(4)
              Recommendations::Result.new(course_id: course.id, course: course, score: score, reason_type: "popular")
            end
            .sort_by { |result| -result.score }
            .take(limit)
    end
  end
end
