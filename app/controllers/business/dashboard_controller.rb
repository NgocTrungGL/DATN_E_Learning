class Business::DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :require_company_admin!
  layout "business"

  def index
    @organization = current_user.organization

    if @organization.nil?
      redirect_to root_path,
                  alert: "Tài khoản của bạn chưa được liên kết với doanh nghiệp nào."
      return
    end

    @total_employees = @organization.users.where(role: :employee).count
  end

  private

  def require_company_admin!
    return if current_user.company_admin?

    redirect_to root_path,
                alert: "Bạn không có quyền truy cập khu vực Doanh nghiệp."
  end
end
