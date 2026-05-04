class NotificationsController < ApplicationController
  before_action :authenticate_user!

  def index
    @notifications = current_user.notifications.recent.pagy_search(params[:q]) if params[:q].present?
    @pagy, @notifications = pagy(current_user.notifications.recent)
  end

  def update
    @notification = current_user.notifications.find(params[:id])
    @notification.mark_as_read!

    respond_to do |format|
      format.html{redirect_back fallback_location: notifications_path}
      format.turbo_stream
    end
  end

  def mark_all_as_read
    current_user.notifications.unread.update_all(read_at: Time.current)

    respond_to do |format|
      format.html{redirect_back fallback_location: notifications_path}
      format.turbo_stream
    end
  end
end
