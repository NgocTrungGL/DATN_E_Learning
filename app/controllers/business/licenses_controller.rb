class Business::LicensesController < ApplicationController
  before_action :authenticate_user!
  before_action :require_company_admin!
  layout "business"

  def index
    @licenses_by_course = current_user.organization.licenses.group_by(&:course)
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

  private

  def require_company_admin!
    return if current_user.company_admin?

    redirect_to root_path, alert: "Không có quyền."
  end

  def available_license
    current_user.organization.licenses
                .find_by(course_id: params[:course_id], status: :available)
  end

  def user_to_assign
    current_user.organization.users.find_by(id: params[:user_id])
  end

  def assign_license license, user
    license.update(user:, status: :assigned)
  end

  def redirect_success license, user
    redirect_to business_licenses_path,
                notice: "Đã cấp khóa
                học '#{license.course.title}' cho #{user.name}."
  end

  def redirect_no_license
    redirect_to business_licenses_path,
                alert: "Hết License trống hoặc không tìm thấy nhân viên!"
  end

  def redirect_error
    redirect_to business_licenses_path, alert: "Có lỗi xảy ra."
  end
end
