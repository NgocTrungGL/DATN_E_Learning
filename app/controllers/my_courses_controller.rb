class MyCoursesController < ApplicationController
  before_action :authenticate_user!

  def index
    @enrollments = current_user.enrollments.active.includes(course: [:creator,
:course_modules])
  end
end
