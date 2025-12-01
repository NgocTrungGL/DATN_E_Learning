class Instructor::DashboardController < Instructor::BaseController
  def index
    @my_courses = current_user.created_courses
  end
end
