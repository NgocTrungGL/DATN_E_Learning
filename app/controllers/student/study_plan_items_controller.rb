class Student::StudyPlanItemsController < Student::BaseController
  before_action :set_study_plan_item, only: [:start, :complete, :skip]

  def start
    if @item.can_start?
      @item.update!(status: :in_progress)
      render json: { success: true, item: item_json }
    else
      render json: { success: false, error: "Cannot start this item" }, status: :unprocessable_entity
    end
  end

  def complete
    if @item.status != "completed"
      @item.mark_completed!

      # Track learning activity
      LearningActivityService.track_activity(
        user: current_user,
        course: @item.lesson.course,
        lesson: @item.lesson,
        activity_type: :lesson_complete,
        duration_seconds: @item.estimated_duration_minutes * 60
      )

      # Update learning streak
      current_user.learning_streak_record.update_streak!(Date.current)

      # Update progress tracking
      tracking = ProgressTracking.find_or_initialize_by(
        user: current_user,
        course: @item.lesson.course,
        lesson: @item.lesson
      )
      tracking.update!(status: :completed, progress_value: 100)

      # Check if plan is complete
      check_plan_completion

      render json: { success: true, item: item_json }
    else
      render json: { success: false, error: "Item already completed" }, status: :unprocessable_entity
    end
  end

  def skip
    if @item.pending? || @item.in_progress?
      @item.update!(status: :skipped, is_replan_needed: true)
      render json: { success: true, item: item_json }
    else
      render json: { success: false, error: "Cannot skip this item" }, status: :unprocessable_entity
    end
  end

  private

  def set_study_plan_item
    @item = current_user.study_plans
                        .joins(:study_plan_items)
                        .where(study_plan_items: { id: params[:id] })
                        .first&.study_plan_items
                        &.find(params[:id])

    return render json: { error: "Item not found" }, status: :not_found unless @item
  end

  def item_json
    plan = @item.study_plan.reload

    {
      id: @item.id,
      status: @item.status,
      status_label: @item.status.humanize,
      lesson_id: @item.lesson_id,
      scheduled_date: @item.scheduled_date,
      actual_completed_at: @item.actual_completed_at,
      plan: {
        status: plan.status,
        status_label: plan.status.humanize,
        progress_percentage: plan.progress_percentage
      }
    }
  end

  def check_plan_completion
    plan = @item.study_plan
    return unless plan.active?

    all_items = plan.study_plan_items
    completed_or_skipped = all_items.where(status: %w[completed skipped]).count

    if completed_or_skipped == all_items.count
      plan.update!(status: :completed, completed_at: Time.current)
    end
  end
end
