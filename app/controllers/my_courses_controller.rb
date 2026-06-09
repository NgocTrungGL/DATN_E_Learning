class MyCoursesController < ApplicationController
  before_action :authenticate_user!

  def index
    @enrollments = current_user.enrollments.active.includes(course: [:creator,
:course_modules])
    @recommended_results = recommended_course_results(limit: 4)
  end
end
