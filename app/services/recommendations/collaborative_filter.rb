module Recommendations
  class CollaborativeFilter
    attr_reader :user

    def initialize(user)
      @user = user
    end

    def call(limit: 50)
      enrolled_ids = user.enrollments.pluck(:course_id)
      return [] if enrolled_ids.empty?

      similar_course_ids = CourseSimilarity
        .where(course_a_id: enrolled_ids)
        .where("score > 0.05")
        .order(score: :desc)
        .pluck(:course_b_id)
        .uniq - enrolled_ids

      return [] if similar_course_ids.empty?

      courses = Course.published
                      .where(id: similar_course_ids)
                      .includes(:category)
                      .limit(limit)

      sim_map = CourseSimilarity
        .where(course_a_id: enrolled_ids, course_b_id: similar_course_ids)
        .index_by(&:course_b_id)

      courses.map do |course|
        Recommendations::Result.new(
          course_id: course.id,
          course: course,
          score: sim_map[course.id]&.score.to_f,
          reason_type: "cf"
        )
      end.sort_by { |r| -r.score }.take(limit)
    end
  end
end
