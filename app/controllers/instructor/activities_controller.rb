class Instructor::ActivitiesController < Instructor::BaseController
  def index
    @activities = []
    @filter = params[:filter].presence || "all"

    # Enrollments
    enrollment_query = Enrollment.joins(:course, :user)
                                .where(course: { created_by: current_user.id })

    enrollment_query = enrollment_query.where("enrollments.created_at >= ?", 30.days.ago) if @filter == "30d"
    enrollment_query = enrollment_query.where("enrollments.created_at >= ?", 7.days.ago) if @filter == "7d"

    enrollment_query.order("enrollments.created_at DESC").limit(50).each do |e|
      @activities << {
        id: "enrollment_#{e.id}",
        type: :enrollment,
        user_name: e.user.name,
        user_email: e.user.email,
        course_title: e.course.title,
        course_id: e.course.id,
        description: "enrolled in",
        data: nil,
        created_at: e.created_at
      }
    end

    # Quiz completions
    quiz_query = QuizAttempt.joins(quiz: :course).joins(:user)
                          .where(course: { created_by: current_user.id })
                          .completed

    quiz_query = quiz_query.where("quiz_attempts.started_at >= ?", 30.days.ago) if @filter == "30d"
    quiz_query = quiz_query.where("quiz_attempts.started_at >= ?", 7.days.ago) if @filter == "7d"

    quiz_query.order("quiz_attempts.started_at DESC").limit(50).each do |qa|
      next if qa.user.nil? || qa.quiz.nil?
      @activities << {
        id: "quiz_#{qa.id}",
        type: :quiz_completion,
        user_name: qa.user.name,
        user_email: qa.user.email,
        course_title: qa.quiz.title,
        course_id: qa.quiz.course_id,
        description: "completed quiz",
        data: { score: qa.score, quiz_title: qa.quiz.title },
        created_at: qa.started_at
      }
    end

    # Reviews
    review_query = Review.joins(:course, :user)
                        .where(courses: { created_by: current_user.id })

    review_query = review_query.where("reviews.created_at >= ?", 30.days.ago) if @filter == "30d"
    review_query = review_query.where("reviews.created_at >= ?", 7.days.ago) if @filter == "7d"

    review_query.order("reviews.created_at DESC").limit(50).each do |r|
      @activities << {
        id: "review_#{r.id}",
        type: :review,
        user_name: r.user.name,
        user_email: r.user.email,
        course_title: r.course.title,
        course_id: r.course.id,
        description: "reviewed",
        data: { rating: r.rating, content: r.content },
        created_at: r.created_at
      }
    end

    @activities.sort_by! { |a| a[:created_at] }.reverse!

    # Simple pagination
    page = params[:page].to_i
    page = 1 if page < 1
    per_page = 25
    offset = (page - 1) * per_page
    @pagy = OpenStruct.new(page: page, pages: (@activities.size.to_f / per_page).ceil, items: @activities.size)
    @activities = @activities.slice(offset, per_page)
  end
end
