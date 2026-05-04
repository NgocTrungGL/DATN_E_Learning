class DiscussionReply < ApplicationRecord
  belongs_to :discussion_post, counter_cache: :replies_count
  belongs_to :user
  belongs_to :parent, class_name: "DiscussionReply", optional: true

  has_many :children, class_name: "DiscussionReply",
                      foreign_key: :parent_id,
                      dependent: :destroy

  validates :content, presence: true

  scope :recent, ->{order(created_at: :asc)}
  scope :top_level, ->{where(parent_id: nil)}

  # Touch the parent post so it "bumps" to the top
  after_create :touch_discussion_post

  def author_name
    user&.name || I18n.t("notifications.common.anonymous")
  end

  def instructor_reply?
    course = discussion_post&.course
    user&.instructor? && course&.created_by == user.id
  end

  after_create_commit :notify_recipient

  private

  def notify_recipient
    notify_post_author
    notify_parent_reply_author
  end

  def touch_discussion_post
    discussion_post.touch
  end

  def notify_post_author
    return if discussion_post.user_id == user_id

    Notification.create(
      user: discussion_post.user,
      title: I18n.t("notifications.reply.post_author.title"),
      body: I18n.t("notifications.reply.post_author.body", user_name: user.name, post_title: discussion_post.title),
      notification_type: "instructor_reply",
      actionable: self
    )
  end

  def notify_parent_reply_author
    return unless parent && parent.user_id != user_id && parent.user_id != discussion_post.user_id

    Notification.create(
      user: parent.user,
      title: I18n.t("notifications.reply.comment_author.title"),
      body: I18n.t("notifications.reply.comment_author.body", user_name: user.name),
      notification_type: "instructor_reply",
      actionable: self
    )
  end
end
