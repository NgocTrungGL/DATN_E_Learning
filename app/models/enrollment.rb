class Enrollment < ApplicationRecord
  belongs_to :user
  belongs_to :course

  enum status: { pending: "pending", active: "active", rejected: "rejected" }
  scope :active, ->{where(status: :active)}
  validates :user_id, uniqueness: { scope: :course_id }

  after_commit :create_enrollment_notification, on: [:create, :update], if: :saved_change_to_status_active?
  after_commit :queue_recommendation_update, on: [:create, :update, :destroy]

  def saved_change_to_status_active?
    saved_change_to_status? && active?
  end

  def queue_recommendation_update
    Recommendations::CacheInvalidator.call(user_id)
  end

  def create_enrollment_notification
    # Notify Student
    Notification.create(
      user:,
      title: I18n.t("notifications.enrollment.student.title"),
      body: I18n.t("notifications.enrollment.student.body", course_title: course.title),
      notification_type: "enrollment",
      actionable: self
    )

    # Notify Instructor
    return unless course.creator

    Notification.create(
      user: course.creator,
      title: I18n.t("notifications.enrollment.instructor.title"),
      body: I18n.t("notifications.enrollment.instructor.body", user_name: user.name, course_title: course.title),
      notification_type: "enrollment",
      actionable: self
    )
  end

  def current_progress_percentage
    user.course_progress_percentage(course)
  end

  def can_review?
    current_progress_percentage >= 70
  end
end
