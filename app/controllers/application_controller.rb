class ApplicationController < ActionController::Base
  layout :layout_by_resource
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :prepare_learning_checkin
  include Pagy::Backend
  def after_sign_in_path_for resource
    if resource.admin?
      admin_courses_path
    elsif resource.company_admin?
      business_root_path
    elsif resource.instructor?
      instructor_root_path
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
  helper_method :current_cart
  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
    devise_parameter_sanitizer.permit(:account_update,
                                      keys: [:name, :avatar_url])
  end
  private

  def store_location
    session[:forwarding_url] = request.original_url if request.get?
  end

  def redirect_back_or default, options = {}
    redirect_to(session[:forwarding_url] || default, options)
    session.delete(:forwarding_url)
  end

  def current_cart
    return unless user_signed_in?

    @current_cart ||= current_user.current_cart
  end

  def recommended_course_results(limit:, exclude_course_ids: [])
    return [] unless user_signed_in?

    excluded_ids = Array(exclude_course_ids).compact.map(&:to_i)
    cart_course_ids = current_user.cart&.cart_items&.pluck(:course_id) || []
    excluded_ids |= cart_course_ids

    fetch_limit = [limit + excluded_ids.size + 8, 50].min
    Recommendations::Engine.new(current_user)
                           .call(limit: fetch_limit)
                           .reject { |result| excluded_ids.include?(result.course_id) }
                           .first(limit)
  end

  def prepare_learning_checkin
    return unless user_signed_in? && current_user.student?
    return unless request.get?
    return unless request.format.html?
    return if devise_controller?
    return if session[:learning_checkin_shown_on] == Date.current.to_s

    plan = current_user.study_plans.active.includes(:course).order(updated_at: :desc).first
    return unless plan

    profile = Learning::BehaviorProfileBuilder.new(
      current_user,
      course: plan.course,
      study_plan: plan
    ).call
    risk = Learning::StudyRiskDetector.new(profile).call
    focus_items = Learning::StudyFocusRecommender.new(profile).call(limit: 2)

    @learning_checkin = {
      plan: plan,
      profile: profile,
      risk: risk,
      focus_items: focus_items
    }
    session[:learning_checkin_shown_on] = Date.current.to_s
  end

  def layout_by_resource
    devise_controller? ? "auth" : "application"
  end
end
