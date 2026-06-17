class Business::LicensesController < ApplicationController
  before_action :authenticate_user!
  before_action :require_company_admin!
  before_action :fulfill_checkout_session, only: :index
  layout "business"

  def index
    @organization = current_user.organization
    @employees = @organization.users.where(role: %i[student employee]).order(:name)
    licenses = @organization.licenses.includes(:course, :user).order(created_at: :desc)

    @license_stats = build_license_stats(licenses)
    @license_course_groups = build_license_course_groups(licenses)
  end

  def assign
    license = available_license
    user = user_to_assign

    return redirect_no_license unless license && user

    if assign_license(license, user)
      redirect_success(license, user)
    else
      redirect_error
    end
  end

  def revoke
    @license = current_user.organization.licenses.find(params[:id])
    return redirect_no_license unless @license.assigned?

    old_user = @license.user
    service = LicenseReassignmentService.new(@license, old_user, nil)

    if service.call
      redirect_to business_licenses_path,
                  notice: "License for '#{@license.course.title}' has been revoked from #{old_user.name}."
    else
      redirect_to business_licenses_path, alert: service.errors.join(", ")
    end
  end

  private

  def require_company_admin!
    return if current_user.company_admin?

    redirect_to root_path, alert: "Không có quyền."
  end

  def fulfill_checkout_session
    return if params[:session_id].blank?

    session = Stripe::Checkout::Session.retrieve(params[:session_id])
    invoice = LicenseCheckoutFulfillmentService.new(session).call
    return unless invoice&.organization_id == current_user.organization_id

    flash.now[:notice] = "Thanh toán thành công. License đã được thêm vào workspace."
  rescue Stripe::StripeError => e
    Rails.logger.warn "[Business::Licenses] Failed to fulfill checkout session: #{e.message}"
    flash.now[:alert] = "Không thể xác nhận phiên thanh toán. Vui lòng tải lại sau ít phút."
  end

  def available_license
    current_user.organization.licenses
                .find_by(course_id: params[:course_id], status: :available)
  end

  def user_to_assign
    current_user.organization.users.find_by(id: params[:user_id])
  end

  def assign_license license, user
    ActiveRecord::Base.transaction do
      license.update!(user: user, status: :assigned)
      enrollment = Enrollment.find_or_initialize_by(user:, course: license.course)
      enrollment.update!(
        price: license.price,
        status: :active,
        enrolled_at: enrollment.enrolled_at || Time.current
      )
    end
    true
  rescue ActiveRecord::RecordInvalid
    false
  end

  def redirect_success license, user
    redirect_to business_licenses_path,
                notice: "Đã cấp khóa học '#{license.course.title}' cho #{user.name}."
  end

  def redirect_no_license
    redirect_to business_licenses_path,
                alert: "Hết License trống hoặc không tìm thấy nhân viên!"
  end

  def redirect_error
    redirect_to business_licenses_path, alert: "Có lỗi xảy ra."
  end

  def build_license_stats licenses
    {
      total: licenses.size,
      assigned: licenses.count(&:assigned?),
      available: licenses.count(&:available?),
      expiring_soon: licenses.count(&:expiring_soon?)
    }
  end

  def build_license_course_groups licenses
    licenses.group_by(&:course).map do |course, course_licenses|
      total_count = course_licenses.size
      available_count = course_licenses.count(&:available?)
      assigned_licenses = course_licenses.select(&:assigned?)
      expiring_count = course_licenses.count(&:expiring_soon?)

      {
        course:,
        licenses: course_licenses,
        total_count:,
        available_count:,
        assigned_count: assigned_licenses.size,
        assigned_licenses:,
        expiring_count:,
        price: course_licenses.first&.price.to_f,
        progress_percent: total_count.positive? ? (assigned_licenses.size.to_f / total_count * 100).round : 0
      }
    end.sort_by { |group| [group[:available_count].zero? ? 1 : 0, group[:course].title.to_s] }
  end
end
