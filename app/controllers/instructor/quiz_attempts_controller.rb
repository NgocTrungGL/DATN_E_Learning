class Instructor::QuizAttemptsController < Instructor::BaseController
  def index
    @course_filter = params[:course].presence

    attempts_scope = QuizAttempt
      .joins(quiz: :course)
      .where(courses: { created_by: current_user.id })
      .includes(user: [], quiz: :course)
      .order("quiz_attempts.started_at DESC")

    if @course_filter.present?
      attempts_scope = attempts_scope.where(courses: { id: @course_filter })
    end

    @pagy, @attempts = pagy(attempts_scope, items: 20)
    @courses = current_user.created_courses.order(:title)
  end
end
