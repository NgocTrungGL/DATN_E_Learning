class DiscussionRepliesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_course
  before_action :set_post
  before_action :ensure_course_member
  before_action :check_post_locked, only: [:create]
  before_action :set_reply, only: [:update, :destroy]

  # POST /courses/:course_id/discussions/:discussion_post_id/replies
  def create
    @reply = @post.discussion_replies.new(reply_params)
    @reply.user = current_user

    if @reply.save
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.append("replies-list",
                                partial: "discussion_replies/reply",
                                locals: {reply: @reply, course: @course,
                                         post: @post}),
            turbo_stream.replace("reply-form",
                                 partial: "discussion_replies/form",
                                 locals: {course: @course, post: @post,
                                          reply: DiscussionReply.new}),
            turbo_stream.replace("replies-count",
                                 partial: "discussion_replies/count",
                                 locals: {count: @post.reload.replies_count})
          ]
        end
        format.html do
          redirect_to course_discussion_post_path(@course, @post),
                      notice: "Đã gửi phản hồi!"
        end
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("reply-form",
                                                    partial: "discussion_replies/form",
                                                    locals: {course: @course,
                                                             post: @post, reply: @reply})
        end
        format.html do
          redirect_to course_discussion_post_path(@course, @post),
                      alert: "Không thể gửi phản hồi."
        end
      end
    end
  end

  # PATCH /courses/:course_id/discussions/:discussion_post_id/replies/:id
  def update
    authorize! :update, @reply
    if @reply.update(reply_params)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(@reply,
                                                    partial: "discussion_replies/reply",
                                                    locals: {reply: @reply,
                                                             course: @course, post: @post})
        end
        format.html do
          redirect_to course_discussion_post_path(@course, @post),
                      notice: "Đã cập nhật!"
        end
      end
    else
      respond_to do |format|
        format.html do
          redirect_to course_discussion_post_path(@course, @post),
                      alert: "Không thể cập nhật."
        end
      end
    end
  end

  # DELETE /courses/:course_id/discussions/:discussion_post_id/replies/:id
  def destroy
    authorize! :destroy, @reply
    @reply.destroy

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.remove(@reply),
          turbo_stream.replace("replies-count",
                               partial: "discussion_replies/count",
                               locals: {count: @post.reload.replies_count})
        ]
      end
      format.html do
        redirect_to course_discussion_post_path(@course, @post),
                    notice: "Đã xóa phản hồi."
      end
    end
  end

  private

  def set_course
    @course = Course.find(params[:course_id])
  end

  def set_post
    @post = @course.discussion_posts.find(params[:discussion_post_id])
  end

  def set_reply
    @reply = @post.discussion_replies.find(params[:id])
  end

  def reply_params
    params.require(:discussion_reply).permit(:content, :parent_id)
  end

  def ensure_course_member
    return if current_user.admin?
    return if current_user.can_access_course?(@course)
    return if @course.created_by == current_user.id
    return if current_user.has_license_for?(@course)

    redirect_to course_path(@course),
                alert: "Bạn cần đăng ký khóa học để tham gia thảo luận."
  end

  def check_post_locked
    return unless @post.locked?

    redirect_to course_discussion_post_path(@course, @post),
                alert: "Bài thảo luận này đã bị khóa."
  end
end
