class Instructor::BaseController < ApplicationController
  layout "instructor"
  before_action :authenticate_user!
  before_action :authorize_instructor_access!

  rescue_from CanCan::AccessDenied do |_exception|
    redirect_to instructor_root_path,
                alert: "Bạn không có quyền truy cập tài nguyên này."
  end

  private

  def authorize_instructor_access!
    authorize! :access, :instructor_dashboard
  end
end
