class Business::InvoicesController < ApplicationController
  before_action :authenticate_user!
  before_action :require_company_admin!
  layout "business"

  def index
    @invoices = current_user.organization.invoices
                            .includes(:course)
                            .latest_first
  end

  def show
    @invoice = current_user.organization.invoices.find(params[:id])
  end

  private

  def require_company_admin!
    redirect_to root_path unless current_user.company_admin?
  end
end
