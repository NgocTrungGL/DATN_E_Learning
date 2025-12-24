class Business::CourseMarketController < ApplicationController
  before_action :authenticate_user!
  before_action :require_company_admin!
  layout "business"

  def index
    @courses = Course.all
  end

  private

  def require_company_admin!
    redirect_to root_path unless current_user.company_admin?
  end
end
