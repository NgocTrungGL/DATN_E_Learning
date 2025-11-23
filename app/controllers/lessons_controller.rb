class LessonsController < ApplicationController
  # before_action :authenticate_user!

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
end
