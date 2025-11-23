class RegistrationsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:new, :create], raise: false

  # GET /signup
  def new
    @user = User.new
  end

  # POST /signup
  def create
    @user = User.new(user_params)
    @user.role = "student"

    if @user.save
      UserMailer.account_activation(@user).deliver_now
      redirect_to root_path,
                  notice: t("registrations.check_email")
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password,
                                 :password_confirmation)
  end
end
