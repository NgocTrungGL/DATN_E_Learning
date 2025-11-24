class EmailConfirmationsController < ApplicationController
  skip_before_action :authenticate_user!
  def edit
    user = find_user_by_signed_id
    return unless user

    return if handle_already_confirmed(user)

    confirm_user(user)
  end

  private

  def find_user_by_signed_id
    user = User.find_signed(params[:id], purpose: :account_activation)
    return user if user.present?

    redirect_to root_path,
                alert: t("email_confirmation.expired_or_invalid_link")
    nil
  end

  def handle_already_confirmed user
    return false if user.confirmed_at.nil?

    redirect_to root_path, alert: t("email_confirmation.already_confirmed")
    true
  end

  def confirm_user user
    user.update!(confirmed_at: Time.current)
    session[:user_id] = user.id
    redirect_back_or root_path, notice: t("email_confirmation.success")
  end
end
