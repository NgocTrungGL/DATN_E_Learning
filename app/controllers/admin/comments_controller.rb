class Admin::CommentsController < Admin::BaseController
  load_and_authorize_resource class: Comment.name

  def index
    @comments = @comments.includes(:user, :lesson).order(created_at: :desc)
  end

  def destroy
    @comment.destroy
    redirect_to admin_comments_path, notice: "Đã xóa bình luận thành công."
  end
end
