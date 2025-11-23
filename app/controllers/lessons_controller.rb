class LessonsController < ApplicationController
  before_action :authenticate_user!
  before_action :check_enrollment_access, only: [:show]
  before_action :set_lesson, only: %i(show)
  layout "learning", only: [:show]
  # GET /lessons/1
  def show
    @course = @lesson.course
  end

  private

  def set_lesson
    @lesson = Lesson.find_by(id: params[:id])

    return unless @lesson.nil?

    redirect_to courses_path, alert: t("lessons.not_found")
  end

  def check_enrollment_access
    return if @lesson.nil?

    course = @lesson.course

    return if current_user&.can_access_course?(course)

    redirect_to course_path(course),
                alert: "Bạn cần đăng ký (hoặc chờ duyệt) để xem bài học này."
  end
end
