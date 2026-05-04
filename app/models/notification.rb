class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :actionable, polymorphic: true, optional: true

  validates :title, :body, presence: true

  after_create :send_email_notification

  scope :unread, ->{where(read_at: nil)}
  scope :read, ->{where.not(read_at: nil)}
  scope :recent, ->{order(created_at: :desc)}

  def unread?
    read_at.nil?
  end

  def read?
    read_at.present?
  end

  def mark_as_read!
    update(read_at: Time.current)
  end

  private

  def send_email_notification
    NotificationMailer.notify(self).deliver_later
  end
end
