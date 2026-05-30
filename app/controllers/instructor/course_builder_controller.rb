class Instructor::CourseBuilderController < Instructor::BaseController
  before_action :set_course

  def show
    @modules = @course.course_modules.includes(:lessons).order(:order_index)
  end

  def sort_modules
    ActiveRecord::Base.transaction do
      params[:module_order].each_with_index do |module_id, index|
        @course.course_modules.find(module_id).update!(order_index: index + 1)
      end
    end
    head :ok
  end

  def sort_lessons
    ActiveRecord::Base.transaction do
      params[:lesson_order].each_with_index do |lesson_json, index|
        data = JSON.parse(lesson_json).with_indifferent_access
        lesson = Lesson.find(data[:id])
        next unless lesson.course_module.course.created_by == current_user.id

        lesson.update!(
          order_index: index + 1,
          course_module_id: data[:module_id]
        )
      end
    end
    head :ok
  end

  private

  def set_course
    @course = current_user.created_courses.find(params[:course_id])
    authorize! :manage, @course
  end
end
