class ApplicationController < ActionController::Base
  include Pagy::Backend
  def after_sign_in_path_for resource
    if resource.admin?
      admin_courses_path
    elsif resource.instructor?
      root_path
    else
      root_path
    end
  end

  rescue_from CanCan::AccessDenied do |_exception|
    if current_user.nil?
      redirect_to new_user_session_path, alert: "Vui lòng đăng nhập."
    elsif current_user.instructor?
      redirect_to instructor_root_path,
                  alert: "Bạn không có quyền thực hiện hành động này."
    else
      redirect_to root_path, alert: "Truy cập bị từ chối."
    end
  end
  private

  def store_location
    session[:forwarding_url] = request.original_url if request.get?
  end

  def redirect_back_or default, options = {}
    redirect_to(session[:forwarding_url] || default, options)
    session.delete(:forwarding_url)
  end
end
