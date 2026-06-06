class StudyPlanItem < ApplicationRecord
  belongs_to :study_plan
  belongs_to :lesson

  enum status: { pending: "pending", in_progress: "in_progress", completed: "completed", skipped: "skipped" }

  scope :pending, -> { where(status: :pending) }
  scope :completed, -> { where(status: :completed) }
  scope :overdue, -> { where("scheduled_date < ?", Date.today).pending }

  def overdue?
    scheduled_date.present? && scheduled_date < Date.today && !completed?
  end

  def completed?
    status == "completed"
  end

  def can_start?
    status == "pending" || status == "in_progress"
  end

  def mark_completed!
    update!(status: :completed, actual_completed_at: Time.current)
  end
end
