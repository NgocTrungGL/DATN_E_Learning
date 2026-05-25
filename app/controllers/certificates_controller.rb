class CertificatesController < ApplicationController
  before_action :authenticate_user!, only: [:index]
  before_action :set_certificate, only: [:show, :print]

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

  # GET /certificates/:code/print - print-optimized certificate page
  def print
    @course = @certificate.course
    @student = @certificate.user
    render layout: "certificate", template: "certificates/print"
  end

  private

  def set_certificate
    @certificate = Certificate.find_by!(certificate_code: params[:code])
  end
end
