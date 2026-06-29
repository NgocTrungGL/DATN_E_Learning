module Recommendations
  class ContentFilter
    attr_reader :user, :interaction_scorer

    def initialize(user, interaction_scorer: InteractionScorer.new(user))
      @user = user
      @interaction_scorer = interaction_scorer
    end

    def call(limit: 50)
      affinities = category_affinities
      positive_category_ids = affinities.select { |_id, score| score.positive? }.keys
      return [] if positive_category_ids.empty?

      enrolled_ids = user.enrollments.pluck(:course_id)
      target_ids = positive_category_ids + parent_category_ids(positive_category_ids)

      courses = Course.published
                      .where.not(id: enrolled_ids)
                      .where(category_id: target_ids)
                      .includes(:category)
                      .limit(limit * 2)

      scored = courses.map do |course|
        direct_score = affinities.fetch(course.category_id, 0.0)
        direct_score = affinities.values.select(&:positive?).max.to_f * 0.5 if direct_score.zero?
        Recommendations::Result.new(
          course_id: course.id,
          course: course,
          score: direct_score,
          reason_type: "content"
        )
      end

      scored.sort_by { |r| -r.score }.take(limit)
    end

    private

    def category_affinities
      course_scores = interaction_scorer.scores
      category_by_course = Course.where(id: course_scores.keys)
                                 .where.not(category_id: nil)
                                 .pluck(:id, :category_id)
                                 .to_h

      course_scores.each_with_object(Hash.new(0.0)) do |(course_id, score), affinities|
        category_id = category_by_course[course_id]
        affinities[category_id] += score if category_id
      end
    end

    def parent_category_ids(category_ids)
      return [] if category_ids.empty?

      Category.where(id: category_ids)
              .where.not(parent_id: nil)
              .pluck(:parent_id)
              .uniq
    end
  end
end
