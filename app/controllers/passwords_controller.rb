class PasswordsController < ApplicationController
  before_action :authenticate_user!

  def edit; end

  def update
    @user = current_user

    unless @user.authenticate(params[:current_password])
      flash.now[:alert] = "Mật khẩu cũ không chính xác."
      render :edit, status: :unprocessable_entity
      return
    end

    if @user.update(password_params)
      redirect_to edit_profile_path, notice: "Đổi mật khẩu thành công."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def password_params
    params.permit(:password, :password_confirmation)
  end
end
