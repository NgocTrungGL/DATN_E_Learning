class DiscussionMessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_course
  before_action :ensure_course_member

  # GET /courses/:course_id/chat
  def index
    @messages = @course.discussion_messages
                       .includes(:user)
                       .chronological
    @members_count = @course.enrollments.active.count
    @message = DiscussionMessage.new
  end

  # POST /courses/:course_id/chat
  def create
    @message = @course.discussion_messages.new(message_params)
    @message.user = current_user

    if @message.save
      @previous_message = @course.discussion_messages
                                 .where("id < ?", @message.id)
                                 .order(created_at: :desc)
                                 .first

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.append("chat-messages",
                                partial: "discussion_messages/message",
                                locals: {message: @message, previous_message: @previous_message,
                                         course: @course}),
            turbo_stream.replace("chat-form",
                                 partial: "discussion_messages/form",
                                 locals: {course: @course,
                                          message: DiscussionMessage.new})
          ]
        end
        format.html{redirect_to course_discussion_messages_path(@course)}
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("chat-form",
                                                    partial: "discussion_messages/form",
                                                    locals: {course: @course,
                                                             message: @message})
        end
        format.html{redirect_to course_discussion_messages_path(@course)}
      end
    end
  end

  # DELETE /courses/:course_id/chat/:id
  def destroy
    @message = @course.discussion_messages.find(params[:id])
    authorize! :destroy, @message
    @message.destroy

    respond_to do |format|
      format.turbo_stream{render turbo_stream: turbo_stream.remove(@message)}
      format.html{redirect_to course_discussion_messages_path(@course)}
    end
  end

  private

  def set_course
    @course = Course.find(params[:course_id])
  end

  def message_params
    params.require(:discussion_message).permit(:content)
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
