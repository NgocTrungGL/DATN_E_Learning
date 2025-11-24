class Admin::BaseController < ApplicationController
  layout "admin"
  before_action :authorize_admin!
  private

  def authorize_admin!
    return if current_user&.admin?

    redirect_to root_path, alert: t("admin.authorization.denied")
  end
end
