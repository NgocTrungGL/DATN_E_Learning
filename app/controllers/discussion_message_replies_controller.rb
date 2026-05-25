class DiscussionMessageRepliesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_course
  before_action :set_parent_message
  before_action :ensure_course_member

  # POST /courses/:course_id/chat/:discussion_message_id/replies
  def create
    @reply = @parent.replies.new(reply_params)
    @reply.course = @course
    @reply.user   = current_user

    if @reply.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to thread_course_discussion_message_path(@course, @parent) }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("reply-form-#{@parent.id}", partial: "discussion_message_replies/form", locals: { course: @course, parent: @parent, reply: @reply }) }
        format.html { redirect_to thread_course_discussion_message_path(@course, @parent) }
      end
    end
  end

  private

  def set_course
    @course = Course.find(params[:course_id])
  end

  def set_parent_message
    @parent = @course.discussion_messages.find(params[:discussion_message_id] || params[:id])
  end

  def reply_params
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
