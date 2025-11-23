class ProgressTrackingsController < ApplicationController
  before_action :authenticate_user!

  # POST /lessons/:lesson_id/complete
  def mark_lesson_complete
    @lesson = Lesson.find(params[:lesson_id])

    progress = current_user.progress_trackings.find_or_initialize_by(
      lesson: @lesson,
      progress_type: "lesson"
    )

    if progress.completed?
      progress.update!(status: :in_progress, progress_value: 0)
      flash[:notice] = "Đã bỏ đánh dấu hoàn thành."
    else
      progress.update!(status: :completed, progress_value: 100)
      flash[:notice] = "Chúc mừng! Bạn đã hoàn thành bài học."
    end

    redirect_to lesson_path(@lesson)
  end
end
