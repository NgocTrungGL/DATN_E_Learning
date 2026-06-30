class HomeController < ApplicationController
  # Skip authentication for the public landing page
  def index
    # Load up to 8 featured published courses with associations
    # Easily replaceable with an API call later
    @featured_courses = Course.published
                              .includes(:category, :creator, :reviews)
                              .recent
                              .limit(8)
    @landing_instructors = build_landing_instructors
    @landing_testimonials = build_landing_testimonials
  end

  private

  def build_landing_instructors
    instructors = User.instructor
                      .joins(:created_courses)
                      .merge(Course.published)
                      .includes(:instructor_profile)
                      .select("users.*, COUNT(courses.id) AS published_courses_count")
                      .group("users.id")
                      .order(Arel.sql("published_courses_count DESC"), created_at: :desc)
                      .limit(4)
                      .to_a

    courses_by_instructor = Course.published
                                  .where(created_by: instructors.map(&:id))
                                  .includes(:category, :reviews, :enrollments)
                                  .group_by(&:created_by)

    instructors.map do |instructor|
      instructor_courses = courses_by_instructor[instructor.id] || []

      {
        initials: instructor_initials(instructor.name),
        avatar_url: instructor.avatar_url,
        name: instructor.name,
        role: instructor_role(instructor_courses),
        bio: instructor_bio(instructor, instructor_courses),
        students: instructor_students_count(instructor_courses),
        courses: instructor_courses.size,
        rating: instructor_rating(instructor_courses)
      }
    end
  end

  def instructor_initials name
    name.to_s.split.first(2).map { |part| part.first.to_s.upcase }.join.presence || "IN"
  end

  def instructor_role courses
    category_name = courses.filter_map { |course| course.category&.name }.tally.max_by { |_name, count| count }&.first
    category_name.present? ? "#{category_name} Instructor" : "Course Instructor"
  end

  def instructor_bio instructor, courses
    profile_bio = instructor.instructor_profile&.bio_detailed.to_s.squish
    return profile_bio.truncate(120) if profile_bio.present?

    category_names = courses.filter_map { |course| course.category&.name }.uniq.first(2)
    return "Instructor with #{courses.size} published courses on the platform." if category_names.blank?

    "Instructor teaching #{category_names.to_sentence} through #{courses.size} published courses."
  end

  def instructor_students_count courses
    courses.sum { |course| course.enrollments.select(&:active?).size }
  end

  def instructor_rating courses
    ratings = courses.flat_map { |course| course.reviews.map(&:rating) }.compact
    return nil if ratings.blank?

    ratings.sum.to_f / ratings.size
  end

  def build_landing_testimonials
    Review.includes(:user, course: :category)
          .joins(:course)
          .merge(Course.published)
          .where.not(content: [nil, ""])
          .order(rating: :desc, created_at: :desc)
          .limit(4)
          .map.with_index do |review, index|
            {
              text: review.content.to_s.squish.truncate(180),
              name: review.user.name,
              title: review.course.title,
              rating: review.rating.to_i,
              initials: instructor_initials(review.user.name),
              avatar_url: review.user.avatar_url,
              bg: testimonial_avatar_background(index)
            }
          end
  end

  def testimonial_avatar_background index
    [
      "linear-gradient(135deg, #2563eb, #4f46e5)",
      "linear-gradient(135deg, #0d9488, #2563eb)",
      "linear-gradient(135deg, #7c3aed, #2563eb)",
      "linear-gradient(135deg, #db2777, #9333ea)"
    ][index % 4]
  end
end
