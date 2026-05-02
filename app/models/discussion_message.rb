class DiscussionMessage < ApplicationRecord
  belongs_to :course
  belongs_to :user

  validates :content, presence: true

  scope :chronological, -> { order(created_at: :asc) }
  scope :recent_window, ->(limit = 100) { order(created_at: :desc).limit(limit) }

  def author_name
    user&.name || "Ẩn danh"
  end

  def author_initial
    author_name[0]&.upcase || "?"
  end

  def instructor_message?
    user&.instructor? && course&.created_by == user_id
  end

  # Check if this message is from the same author as the previous one
  # and within 5 minutes — used for message grouping in the UI
  def same_group_as?(other)
    return false if other.nil?

    user_id == other.user_id &&
      (created_at - other.created_at).abs < 5.minutes
  end
end
