class CoursesController < ApplicationController
  def index
    @courses = Course.includes(:category).recent
  end

  def show
    @course = Course.includes(course_modules: :lessons).find_by(id: params[:id])
    return redirect_to courses_path if @course.nil?

    @big_quizzes = @course.quizzes.big
  end
end
