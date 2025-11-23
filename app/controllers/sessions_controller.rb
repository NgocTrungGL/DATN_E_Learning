class SessionsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:new, :create], raise: false

  # GET /login
  def new
    return unless logged_in?

    redirect_based_on_role
  end

  # POST /login
  def create
    user = User.find_by(email: params[:email])

    return render_invalid_credentials unless valid_credentials?(user)
    return render_account_not_activated if user.confirmed_at.blank?

    login(user)
  end

  # DELETE /logout
  def destroy
    session[:user_id] = nil
    redirect_to login_path, notice: t("sessions.logout_success")
  end

  private

  def redirect_based_on_role user = current_user
    if user.admin?
      redirect_to admin_courses_path
    else
      redirect_to root_path
    end
  end

  def valid_credentials? user
    user&.authenticate(params[:password])
  end

  def render_invalid_credentials
    flash.now[:alert] = t("sessions.invalid_credentials")
    render :new, status: :unprocessable_entity
  end

  def render_account_not_activated
    flash.now[:alert] = t("sessions.account_not_activated")
    render :new, status: :unprocessable_entity
  end

  def login user
    session[:user_id] = user.id
    flash[:notice] = t("sessions.login_success")
    redirect_back_or root_path
  end
end
