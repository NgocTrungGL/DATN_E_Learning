class DiscussionMessageReactionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_course
  before_action :set_message
  before_action :ensure_course_member

  # POST /courses/:course_id/chat/:id/toggle_reaction
  def create
    emoji = params[:emoji]
    if emoji.present?
      reaction = @message.reactions.find_or_initialize_by(user: current_user, emoji: emoji)
      if reaction.persisted?
        reaction.destroy
      else
        reaction.save
      end
    end

    respond_to do |format|
      format.turbo_stream {
        render turbo_stream: turbo_stream.replace(
          "msg-reactions-#{@message.id}",
          partial: "discussion_messages/reactions",
          locals: { message: @message.reload, course: @course }
        )
      }
      format.html { redirect_to course_discussion_messages_path(@course) }
    end
  end

  private

  def set_course
    @course = Course.find(params[:course_id])
  end

  def set_message
    @message = @course.discussion_messages.find(params[:id])
  end

  def ensure_course_member
    return if current_user.admin?
    return if current_user.can_access_course?(@course)
    return if @course.created_by == current_user.id
    return if current_user.has_license_for?(@course)

    redirect_to course_path(@course),
                alert: "Bạn cần đăng ký khóa học để tham gia nhóm trao đổi."
  end
end
