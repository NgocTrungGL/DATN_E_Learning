class ProfilesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user

  # GET /profile/edit
  def edit; end

  # PATCH /profile
  def update
    if @user.update(profile_params)
      redirect_to edit_profile_path,
                  notice: "Hồ sơ đã được cập nhật thành công!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = current_user
  end

  def profile_params
    params.require(:user).permit(
      :name, :email, :avatar_url,
      profile_attributes: [:id, :bio, :phone, :gender, :dob]
    )
  end
end
