class Certificate < ApplicationRecord
  belongs_to :user
  belongs_to :course

  validates :certificate_code, presence: true, uniqueness: true
  validates :user_id, uniqueness: { scope: :course_id, message: "already has a certificate for this course" }
  validates :issued_at, presence: true

  before_validation :generate_certificate_code, on: :create
  before_validation :set_issued_at, on: :create

  after_create_commit :notify_user

  scope :recent, ->{order(issued_at: :desc)}

  # Class method: issue certificate if student is eligible
  def self.issue_for user, course
    return nil if exists?(user:, course:)
    return nil unless user.course_progress_percentage(course) >= 100

    create!(user:, course:, template_type: "classic")
  end

  private

  def generate_certificate_code
    self.certificate_code ||= "CERT-#{SecureRandom.alphanumeric(8).upcase}-#{Time.current.strftime('%Y%m')}"
  end

  def set_issued_at
    self.issued_at ||= Time.current
  end

  def notify_user
    Notification.create(
      user:,
      title: I18n.t("notifications.certificate.title"),
      body: I18n.t("notifications.certificate.body", course_title: course.title),
      notification_type: "certificate",
      actionable: self
    )
  end
end
