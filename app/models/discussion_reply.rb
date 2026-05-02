class DiscussionReply < ApplicationRecord
  belongs_to :discussion_post, counter_cache: :replies_count
  belongs_to :user
  belongs_to :parent, class_name: "DiscussionReply", optional: true

  has_many :children, class_name: "DiscussionReply",
                      foreign_key: :parent_id,
                      dependent: :destroy

  validates :content, presence: true

  scope :recent, -> { order(created_at: :asc) }
  scope :top_level, -> { where(parent_id: nil) }

  # Touch the parent post so it "bumps" to the top
  after_create :touch_discussion_post

  def author_name
    user&.name || "Ẩn danh"
  end

  def instructor_reply?
    course = discussion_post&.course
    user&.instructor? && course&.created_by == user.id
  end

  private

  def touch_discussion_post
    discussion_post.touch
  end
end
