module Recommendations
  class CollaborativeFilter
    attr_reader :user, :interaction_scorer

    def initialize(user, interaction_scorer: InteractionScorer.new(user))
      @user = user
      @interaction_scorer = interaction_scorer
    end

    def call(limit: 50)
      source_scores = interaction_scorer.scores
      return [] if source_scores.empty?

      excluded_ids = interaction_scorer.interacted_course_ids
      similarities = CourseSimilarity
        .where(course_a_id: source_scores.keys)
        .where("score > 0.05")
        .to_a

      candidate_scores = similarities.each_with_object(Hash.new(0.0)) do |similarity, scores|
        scores[similarity.course_b_id] += similarity.score.to_f *
                                          source_scores[similarity.course_a_id]
      end
      candidate_scores.except!(*excluded_ids)
      candidate_scores.select! { |_course_id, score| score.positive? }

      return [] if candidate_scores.empty?

      courses = Course.published
                      .where(id: candidate_scores.keys)
                      .includes(:category)
                      .index_by(&:id)

      normalizer = source_scores.values.sum(&:abs).nonzero? || 1.0

      candidate_scores.filter_map do |course_id, score|
        course = courses[course_id]
        next unless course

        Recommendations::Result.new(
          course_id: course.id,
          course: course,
          score: score / normalizer,
          reason_type: "cf"
        )
      end.sort_by { |r| -r.score }.take(limit)
    end
  end
end
