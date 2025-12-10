class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: [:destroy]
  before_action :prevent_self_delete, only: [:destroy]
  def index
    @pagy, @users = pagy(User.recent)
  end

  def destroy
    @user.destroy
    redirect_to admin_users_path, notice: "Đã xóa người dùng #{@user.name}."
  end

  private

  def set_user
    @user = User.find_by(id: params[:id])
    return if @user.present?

    redirect_to admin_users_path, alert: "Không tìm thấy người dùng."
  end

  def prevent_self_delete
    return unless @user == current_user

    redirect_to admin_users_path, alert: "Không thể tự xóa chính mình!"
  end
end
