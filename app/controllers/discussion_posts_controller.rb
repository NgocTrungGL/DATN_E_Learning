class DiscussionPostsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_course
  before_action :ensure_course_member
  before_action :set_post, only: [:show, :update, :destroy, :toggle_pin, :toggle_lock]

  # GET /courses/:course_id/discussions
  def index
    @posts = @course.discussion_posts
                    .includes(:user)
                    .pinned_first
    @post = DiscussionPost.new
  end

  # GET /courses/:course_id/discussions/:id
  def show
    @replies = @post.discussion_replies
                    .top_level
                    .includes(:user, children: :user)
                    .recent
    @reply = DiscussionReply.new
  end

  # POST /courses/:course_id/discussions
  def create
    @post = @course.discussion_posts.new(post_params)
    @post.user = current_user

    if @post.save
      redirect_to course_discussion_post_path(@course, @post),
                  notice: "Đã đăng bài thảo luận!"
    else
      @posts = @course.discussion_posts.includes(:user).pinned_first
      render :index, status: :unprocessable_entity
    end
  end

  # PATCH /courses/:course_id/discussions/:id
  def update
    authorize! :update, @post
    if @post.update(post_params)
      redirect_to course_discussion_post_path(@course, @post),
                  notice: "Đã cập nhật bài viết!"
    else
      @replies = @post.discussion_replies.top_level.includes(:user, children: :user).recent
      @reply = DiscussionReply.new
      render :show, status: :unprocessable_entity
    end
  end

  # DELETE /courses/:course_id/discussions/:id
  def destroy
    authorize! :destroy, @post
    @post.destroy
    redirect_to course_discussion_posts_path(@course),
                notice: "Đã xóa bài thảo luận."
  end

  # PATCH /courses/:course_id/discussions/:id/toggle_pin
  def toggle_pin
    authorize_instructor!
    @post.update(pinned: !@post.pinned)
    redirect_to course_discussion_posts_path(@course),
                notice: @post.pinned? ? "Đã ghim bài viết." : "Đã bỏ ghim."
  end

  # PATCH /courses/:course_id/discussions/:id/toggle_lock
  def toggle_lock
    authorize_instructor!
    @post.update(locked: !@post.locked)
    redirect_to course_discussion_post_path(@course, @post),
                notice: @post.locked? ? "Đã khóa thảo luận." : "Đã mở khóa."
  end

  private

  def set_course
    @course = Course.find(params[:course_id])
  end

  def set_post
    @post = @course.discussion_posts.find(params[:id])
  end

  def post_params
    params.require(:discussion_post).permit(:title, :content)
  end

  def ensure_course_member
    return if current_user.admin?
    return if current_user.can_access_course?(@course)
    return if @course.created_by == current_user.id
    return if current_user.has_license_for?(@course)

    redirect_to course_path(@course),
                alert: "Bạn cần đăng ký khóa học để tham gia thảo luận."
  end

  def authorize_instructor!
    unless current_user.admin? || @course.created_by == current_user.id
      redirect_to course_discussion_posts_path(@course),
                  alert: "Chỉ giảng viên mới có quyền thực hiện thao tác này."
    end
  end
end
