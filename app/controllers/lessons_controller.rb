class LessonsController < ApplicationController
  before_action :set_lesson, only: [:show]
  before_action :authenticate_user!, except: [:show]

  layout "learning", only: [:show]

  # GET /lessons/1
  def show
    @course = @lesson.course_module.course
    authenticate_user! if !@lesson.free_preview? && !user_signed_in?
    authorize! :read, @lesson
  end

  private

  def set_lesson
    @lesson = Lesson.find_by(id: params[:id])

    return unless @lesson.nil?

    redirect_to courses_path, alert: "Bài học không tồn tại."
  end
end
