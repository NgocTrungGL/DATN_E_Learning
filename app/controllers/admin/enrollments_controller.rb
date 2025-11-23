class Admin::EnrollmentsController < Admin::BaseController
  # GET /admin/enrollments
  def index
    @pending_enrollments = Enrollment.pending.includes(:user,
                                                       :course)
                                     .order(created_at: :desc)

    @history_enrollments = Enrollment.where.not(status: :pending).includes(
      :user, :course
    ).order(updated_at: :desc).limit(50)
  end

  # PATCH /admin/enrollments/:id/approve
  def approve
    enrollment = Enrollment.find(params[:id])
    if enrollment.active!
      redirect_to admin_enrollments_path,
                  notice: "Đã duyệt học viên #{enrollment.user.name}."
    else
      redirect_to admin_enrollments_path, alert: "Không thể duyệt."
    end
  end

  # PATCH /admin/enrollments/:id/reject
  def reject
    enrollment = Enrollment.find(params[:id])
    if enrollment.rejected!
      redirect_to admin_enrollments_path, notice: "Đã từ chối yêu cầu."
    else
      redirect_to admin_enrollments_path, alert: "Lỗi hệ thống."
    end
  end
end
