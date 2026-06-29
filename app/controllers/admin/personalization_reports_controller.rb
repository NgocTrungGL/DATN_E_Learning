# Hiển thị báo cáo demo pipeline cá nhân hóa học tập cho hội đồng và admin.
class Admin::PersonalizationReportsController < Admin::BaseController
  skip_load_and_authorize_resource
  before_action :authorize_personalization_report

  def index
    @report = Learning::BehaviorPersonalizationReport.new(
      user_id: params[:user_id],
      course_id: params[:course_id]
    ).call
  end

  def refresh_demo
    result = Learning::BehaviorDemoDataBuilder.new(
      email: params[:email],
      course_id: params[:course_id]
    ).call

    redirect_to admin_personalization_reports_path(
      user_id: result.user.id,
      course_id: result.course.id
    ), notice: "Demo personalization data was refreshed."
  end

  private

  def authorize_personalization_report
    authorize! :access, :admin_dashboard
  end
end
