class Admin::EnrollmentsController < Admin::BaseController
  def index
    scope = Enrollment.includes(:user, :course).order(created_at: :desc)

    scope = scope.where(status: params[:status]) if params[:status].present?

    @pagy, @enrollments = pagy(scope, items: 20)
  end

  def destroy
    enrollment = Enrollment.find_by(id: params[:id])

    if enrollment&.destroy
      redirect_back fallback_location: admin_enrollments_path,
                    notice: "Đã xóa bản ghi ghi danh."
    else
      redirect_back fallback_location: admin_enrollments_path,
                    alert: "Không tìm thấy hoặc lỗi khi xóa."
    end
  end
end
