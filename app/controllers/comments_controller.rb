class CommentsController < ApplicationController
  before_action :authenticate_user!

  def create
    @lesson = Lesson.find_by(id: params[:lesson_id])

    unless @lesson
      return redirect_back fallback_location: courses_path,
                           alert: "Bài học không tồn tại."
    end

    @comment = @lesson.comments.build(comment_params)
    @comment.user = current_user

    if @comment.save
      redirect_to course_lesson_path(@lesson.course, @lesson),
                  notice: "Đã gửi bình luận."
    else
      redirect_to course_lesson_path(@lesson.course, @lesson),
                  alert: "Bình luận không được để trống."
    end
  end

  private

  def comment_params
    params.require(:comment).permit(:body, :parent_id)
  end
end
