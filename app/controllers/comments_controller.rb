class CommentsController < ApplicationController
  before_action :authenticate_user!

  def create
    @lesson = Lesson.find_by(id: params[:lesson_id])

    unless @lesson
      redirect_to root_path, alert: "Bài học không tồn tại."
      return
    end

    @comment = @lesson.comments.build(comment_params)
    @comment.user = current_user

    if @comment.save
      redirect_to lesson_path(@lesson, anchor: "comment-#{@comment.id}"),
                  notice: "Đã gửi bình luận."
    else
      redirect_to lesson_path(@lesson),
                  alert: "Nội dung bình luận không được để trống."
    end
  end

  def destroy
    @comment = current_user.comments.find_by(id: params[:id])

    if @comment
      @comment.destroy
      redirect_back(fallback_location: root_path, notice: "Đã xóa bình luận.")
    else
      redirect_back(fallback_location: root_path,
                    alert: "Bạn không có quyền xóa bình luận này.")
    end
  end

  private

  def comment_params
    params.require(:comment).permit(:body, :parent_id)
  end
end
