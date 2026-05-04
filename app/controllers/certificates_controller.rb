class CertificatesController < ApplicationController
  before_action :authenticate_user!, only: [:index]
  before_action :set_certificate, only: [:show]

  # GET /my_certificates -  logged-in student's certificates
  def index
    @certificates = current_user.certificates.includes(:course).recent
  end

  # GET /certificates/:code - public verification page
  def show
    @course = @certificate.course
    @student = @certificate.user
    render layout: "certificate"
  end

  private

  def set_certificate
    @certificate = Certificate.find_by!(certificate_code: params[:code])
  end
end
