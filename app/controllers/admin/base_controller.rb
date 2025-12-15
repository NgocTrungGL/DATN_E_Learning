class Admin::BaseController < ApplicationController
  layout "admin"
  load_and_authorize_resource
  before_action :ensure_admin_access!

  private

  def ensure_admin_access!
    authorize! :access, :admin_dashboard
  end
end
