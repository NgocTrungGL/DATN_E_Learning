class Admin::InstructorProfilesController < Admin::BaseController
  before_action :set_instructor_profile, only: [:show, :approve, :reject]
  def index
    authorize! :read, InstructorProfile

    status_order =
      "FIELD(status, 'pending', 'approved', 'rejected')"

    @instructor_profiles = InstructorProfile
                           .includes(:user)
                           .order(Arel.sql(status_order))
                           .order(created_at: :desc)
  end

  def show
    authorize! :read, @instructor_profile
  end

  def approve
    authorize! :update, @instructor_profile
    ActiveRecord::Base.transaction do
      @instructor_profile.update!(status: :approved)
      @instructor_profile.user.update!(role: :instructor)
    end
    redirect_to admin_instructor_profiles_path,
                notice: "Đã duyệt giảng viên #{@instructor_profile.user.name}."
  rescue StandardError => e
    redirect_to admin_instructor_profiles_path,
                alert: "Đã xảy ra lỗi: #{e.message}"
  end

  def reject
    authorize! :update, @instructor_profile
    if @instructor_profile.update(status: :rejected)
      redirect_to admin_instructor_profiles_path,
                  notice: "Từ chối yêu cầu của #{@instructor_profile.user.name}"
    else
      redirect_to admin_instructor_profiles_path,
                  alert: "Không thể cập nhật trạng thái."
    end
  end

  private

  def set_instructor_profile
    @instructor_profile = InstructorProfile.find_by(id: params[:id])
    return if @instructor_profile.present?

    redirect_to instructor_profiles_path, alert: "Instructor not found."
  end
end
