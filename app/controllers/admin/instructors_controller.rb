class Admin::InstructorsController < Admin::BaseController
  load_and_authorize_resource class: "InstructorProfile"

  def index
    @instructor_profiles = InstructorProfile
                           .includes(:user)
                           .order
    Arel.sql("FIELD(status, 'pending', 'approved', 'rejected')")
        .order(created_at: :desc)
  end

  def approve
    ActiveRecord::Base.transaction do
      @instructor_profile.update!(status: :approved)
      @instructor_profile.user.update!(role: :instructor)
    end

    redirect_to admin_instructors_path,
                notice: "Đã duyệt giảng viên #{@instructor_profile.user.name}."
  rescue StandardError => e
    redirect_to admin_instructors_path, alert: "Lỗi: #{e.message}"
  end

  def reject
    @instructor_profile.update!(status: :rejected)
    redirect_to admin_instructors_path, notice: "Đã từ chối yêu cầu."
  end
end
