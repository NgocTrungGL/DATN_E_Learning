module Recommendations
  # Dung Bayesian Average de cham diem popularity.
  # Khong phu thuoc vao interaction data cua user.
  class PopularityScorer
    C = 5  # Bayesian prior: gia su co 5 review muc trung binh

    attr_reader :user, :exclude_enrolled_for, :exclude_course_ids

    def initialize(user: nil, exclude_enrolled_for: nil, exclude_course_ids: [])
      @user = user
      @exclude_enrolled_for = exclude_enrolled_for
      @exclude_course_ids = Array(exclude_course_ids).compact.map(&:to_i)
    end

    def call(limit: 50)
      excluded_ids = exclude_course_ids
      if exclude_enrolled_for
        excluded_ids |= InteractionScorer.new(exclude_enrolled_for).interacted_course_ids
      end

      courses = Course.published
                      .where.not(id: excluded_ids)
                      .left_joins(:reviews, :enrollments)
                      .group("courses.id")
                      .select(
                        "courses.*",
                        "COUNT(DISTINCT reviews.id) AS review_count",
                        "AVG(reviews.rating) AS avg_rating",
                        "COUNT(DISTINCT enrollments.id) AS enrollment_count"
                      )

      global_mean = Review.average(:rating).to_f.nonzero? || 3.5

      results = courses.map do |course|
        n = course.review_count.to_i
        avg = course.avg_rating.to_f

        bayesian = (C * global_mean + n * avg) / (C + n)

        bayesian_norm = bayesian / 5.0
        volume_norm = Math.log10(course.enrollment_count.to_i + 1) / 5.0
        score = (0.7 * bayesian_norm + 0.3 * volume_norm).round(4)

        Recommendations::Result.new(
          course_id: course.id,
          course: course,
          score: score,
          reason_type: "popular"
        )
      end

      results.sort_by { |r| -r.score }.take(limit)
    end
  end
end
