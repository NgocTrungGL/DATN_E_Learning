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

  # POST /lessons/:lesson_id/video_progress
  def video_progress
    @lesson = Lesson.find(params[:lesson_id])

    progress_value = params[:progress].to_i.clamp(0, 100)

    progress = current_user.progress_trackings.find_or_initialize_by(
      lesson: @lesson,
      progress_type: "lesson"
    )

    # Chỉ cập nhật nếu progress mới lớn hơn progress cũ
    if progress.progress_value.to_i < progress_value
      progress.progress_value = progress_value
      progress.status = :in_progress if progress.status.nil? || progress.status == "not_started"
      progress.save!
    end

    head :ok
  end

  # POST /lessons/:lesson_id/auto_complete
  # Tự động đánh dấu hoàn thành khi xem video > 80%
  def auto_complete
    @lesson = Lesson.find(params[:lesson_id])

    unless @lesson.video?
      head :forbidden and return
    end

    progress = current_user.progress_trackings.find_or_initialize_by(
      lesson: @lesson,
      progress_type: "lesson"
    )

    unless progress.completed?
      progress.update!(status: :completed, progress_value: 100)
    end

    head :ok
  end

  # GET /lessons/:lesson_id/progress
  # Tra ve progress percentage cua khoa hoc hien tai
  def get_progress
    @lesson = Lesson.find(params[:lesson_id])
    course = @lesson.course
    percentage = current_user.course_progress_percentage(course)

    render json: { progress: percentage }
  end
end
