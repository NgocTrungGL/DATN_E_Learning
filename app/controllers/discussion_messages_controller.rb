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
      @previous_message = previous_message
      respond_to_message_created
    else
      respond_to_message_invalid
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

  def previous_message
    @course.discussion_messages
           .where("id < ?", @message.id)
           .order(created_at: :desc)
           .first
  end

  def respond_to_message_created
    respond_to do |format|
      format.turbo_stream{render turbo_stream: message_created_streams}
      format.html{redirect_to course_discussion_messages_path(@course)}
    end
  end

  def message_created_streams
    [
      turbo_stream.append("chat-messages",
                          partial: "discussion_messages/message",
                          locals: message_locals),
      turbo_stream.replace("chat-form",
                           partial: "discussion_messages/form",
                           locals: new_message_form_locals)
    ]
  end

  def respond_to_message_invalid
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("chat-form",
                                                  partial: "discussion_messages/form",
                                                  locals: message_form_locals)
      end
      format.html{redirect_to course_discussion_messages_path(@course)}
    end
  end

  def message_locals
    { message: @message, previous_message: @previous_message, course: @course }
  end

  def new_message_form_locals
    { course: @course, message: DiscussionMessage.new }
  end

  def message_form_locals
    { course: @course, message: @message }
  end
end
