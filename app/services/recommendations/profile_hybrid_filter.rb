module Recommendations
  class ProfileHybridFilter
    attr_reader :profile_interactions, :excluded_course_ids,
                :course_similarities, :evaluation_user_id, :training_cutoff

    def initialize(profile_interactions:, excluded_course_ids: [],
                   course_similarities: nil, evaluation_user_id: nil,
                   training_cutoff: nil)
      @profile_interactions = profile_interactions.to_h
                                                 .transform_keys(&:to_i)
                                                 .transform_values(&:to_f)
      @excluded_course_ids = Array(excluded_course_ids).map(&:to_i)
      @course_similarities = course_similarities
      @evaluation_user_id = evaluation_user_id
      @training_cutoff = training_cutoff
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
      candidate_scores = relevant_similarities
                         .each_with_object(Hash.new(0.0)) do |similarity, scores|
        scores[similarity.course_b_id] += similarity.score.to_f *
                                          profile_interactions[similarity.course_a_id]
      end
      candidate_scores.except!(*excluded_ids)
      candidate_scores.select! { |_course_id, score| score.positive? }
      return [] if candidate_scores.empty?

      courses = Course.published
                      .where(id: candidate_scores.keys)
                      .includes(:category, :creator)
                      .index_by(&:id)
      normalizer = profile_interactions.values.sum(&:abs).nonzero? || 1.0

      candidate_scores.filter_map do |course_id, score|
        course = courses[course_id]
        next unless course

        Recommendations::Result.new(
          course_id: course_id,
          course: course,
          score: score / normalizer,
          reason_type: "cf"
        )
      end.sort_by { |result| -result.score }.take(limit)
    end

    def content_results(limit:)
      category_by_course = Course.where(id: source_course_ids)
                                 .where.not(category_id: nil)
                                 .pluck(:id, :category_id)
                                 .to_h
      affinities = profile_interactions.each_with_object(Hash.new(0.0)) do |(course_id, weight), scores|
        category_id = category_by_course[course_id]
        scores[category_id] += weight if category_id
      end
      category_ids = affinities.select { |_id, score| score.positive? }.keys
      return [] if category_ids.empty?

      parent_ids = Category.where(id: category_ids).where.not(parent_id: nil).pluck(:parent_id)
      target_category_ids = (category_ids | parent_ids).compact

      Course.published
            .where(category_id: target_category_ids)
            .where.not(id: excluded_ids)
            .includes(:category, :creator)
            .limit(limit * 2)
            .map do |course|
              score = affinities.fetch(course.category_id, 0.0)
              score = affinities.values.select(&:positive?).max.to_f * 0.5 if score.zero?
              Recommendations::Result.new(course_id: course.id, course: course, score: score, reason_type: "content")
            end
            .sort_by { |result| -result.score }
            .take(limit)
    end

    def popular_results(limit:)
      global_mean = popularity_reviews.average(:rating).to_f.nonzero? || 3.5

      review_condition = aggregate_condition("reviews", "reviews.created_at")
      enrollment_condition = aggregate_condition(
        "enrollments",
        "COALESCE(enrollments.enrolled_at, enrollments.created_at)"
      )
      enrollment_condition += " AND enrollments.status = 'active'"

      Course.published
            .where.not(id: excluded_ids)
            .left_joins(:reviews, :enrollments)
            .group("courses.id")
            .select(
              "courses.*",
              "COUNT(DISTINCT CASE WHEN #{review_condition} THEN reviews.id END) AS review_count",
              "AVG(CASE WHEN #{review_condition} THEN reviews.rating END) AS avg_rating",
              "COUNT(DISTINCT CASE WHEN #{enrollment_condition} THEN enrollments.id END) AS enrollment_count"
            )
            .map do |course|
              n = course.review_count.to_i
              avg = course.avg_rating.to_f
              bayesian = (PopularityScorer::C * global_mean + n * avg) / (PopularityScorer::C + n)
              volume_norm = Math.log10(course.enrollment_count.to_i + 1) / 5.0
              score = (0.7 * (bayesian / 5.0) + 0.3 * volume_norm).round(4)
              Recommendations::Result.new(course_id: course.id, course: course, score: score, reason_type: "popular")
            end
            .sort_by { |result| -result.score }
            .take(limit)
    end

    def relevant_similarities
      return course_similarities if course_similarities

      CourseSimilarity.where(course_a_id: source_course_ids)
                      .where("score > 0.05")
    end

    def popularity_reviews
      scope = Review.all
      scope = scope.where.not(user_id: evaluation_user_id) if evaluation_user_id
      scope = scope.where("created_at <= ?", training_cutoff) if training_cutoff
      scope
    end

    def aggregate_condition(table, timestamp_expression)
      conditions = ["TRUE"]
      if evaluation_user_id
        conditions << "#{table}.user_id <> #{evaluation_user_id.to_i}"
      end
      if training_cutoff
        quoted_cutoff = ActiveRecord::Base.connection.quote(training_cutoff)
        conditions << "#{timestamp_expression} <= #{quoted_cutoff}"
      end
      conditions.join(" AND ")
    end
  end
end
