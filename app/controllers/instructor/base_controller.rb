class Instructor::BaseController < ApplicationController
  layout "instructor"
  before_action :authenticate_user! # Devise

  before_action :authorize_instructor_access!

  private

  def authorize_instructor_access!
    authorize! :access, :instructor_dashboard
  end
end
