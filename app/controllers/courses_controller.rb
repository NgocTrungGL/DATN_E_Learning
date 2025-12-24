class CoursesController < ApplicationController
  def index
    @courses = Course.published.includes(:category, :creator).recent
  end

  def show
    @course = Course.published
                    .includes(course_modules: :lessons).find_by(id: params[:id])

    if @course.nil?
      redirect_to courses_path,
                  alert: "Khóa học không tồn tại hoặc chưa được công khai."
      return
    end

    @big_quizzes = @course.quizzes.big
  end
end
