class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  helper_method :current_user, :logged_in?, :admin?

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def logged_in?
    current_user.present?
  end

  def authenticate_user!
    return if logged_in?

    redirect_to login_path, alert: t("sessions.require_login")
  end

  def authorize_admin!
    return if current_user&.admin?

    redirect_to root_path, alert: t("admin.authorization.denied")
  end

  def store_location
    session[:forwarding_url] = request.original_url if request.get?
  end

  def redirect_back_or default, options = {}
    redirect_to(session[:forwarding_url] || default, options)
    session.delete(:forwarding_url)
  end
end
