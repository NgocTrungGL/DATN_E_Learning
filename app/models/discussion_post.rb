class DiscussionPost < ApplicationRecord
  belongs_to :course
  belongs_to :user

  has_many :discussion_replies, dependent: :destroy
  has_many :replies, class_name: "DiscussionReply", dependent: :destroy

  validates :title, presence: true, length: { maximum: 200 }
  validates :content, presence: true

  scope :pinned_first, ->{order(pinned: :desc, updated_at: :desc)}
  scope :recent, ->{order(updated_at: :desc)}

  def author_name
    user&.name || "Ẩn danh"
  end

  def locked?
    locked
  end

  def pinned?
    pinned
  end

  def instructor_post?
    user&.instructor? && course.created_by == user.id
  end
end
