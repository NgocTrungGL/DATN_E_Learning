module Recommendations
  class ContentFilter
    attr_reader :user

    def initialize(user)
      @user = user
    end

    def call(limit: 50)
      category_ids = collect_category_ids
      return [] if category_ids.empty?

      enrolled_ids = user.enrollments.pluck(:course_id)
      return [] if enrolled_ids.empty?

      courses = Course.published
                      .where.not(id: enrolled_ids)
                      .where(category_id: category_ids + parent_category_ids(category_ids))
                      .includes(:category)
                      .limit(limit * 2)

      scored = courses.map do |course|
        direct_score = category_ids.include?(course.category_id) ? 1.0 : 0.5
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

    def collect_category_ids
      ids = []

      user.enrollments.includes(:course).each do |e|
        ids << e.course.category_id if e.course.category_id
      end

      user.wishlists.includes(course: :category).each do |w|
        ids << w.course.category_id if w.course.category_id
      end

      ids.uniq
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
