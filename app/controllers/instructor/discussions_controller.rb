class Instructor::DiscussionsController < Instructor::BaseController
  def index
    @course_filter = params[:course].presence

    courses_scope = current_user.created_courses
                               .includes(:enrollments)
                               .order(created_at: :desc)

    if @course_filter.present?
      courses_scope = courses_scope.where(id: @course_filter)
    end

    @pagy, @courses = pagy(courses_scope, items: 12)
  end
end
