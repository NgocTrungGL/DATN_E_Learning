class Business::CourseMarketController < ApplicationController
  before_action :authenticate_user!
  before_action :require_company_admin!
  layout "business"

  def index
    @search = params[:search].presence
    @courses = Course.all

    if @search.present?
      @courses = @courses.where("title LIKE ?", "%#{@search}%")
    end

    @pagy, @courses = pagy(@courses.order(created_at: :desc), items: 12)
  end

  private

  def require_company_admin!
    redirect_to root_path unless current_user.company_admin?
  end
end
