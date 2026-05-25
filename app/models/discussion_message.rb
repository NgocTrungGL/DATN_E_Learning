class DiscussionMessage < ApplicationRecord
  belongs_to :course
  belongs_to :user
  belongs_to :parent, class_name: "DiscussionMessage", optional: true
  has_many :replies, class_name: "DiscussionMessage", foreign_key: :parent_id,
                     dependent: :destroy, counter_cache: :replies_count
  has_many :reactions, class_name: "MessageReaction", dependent: :destroy

  validates :content, presence: true

  scope :chronological, -> { order(created_at: :asc) }
  scope :top_level,     -> { where(parent_id: nil) }

  after_create_commit do
    self.class.reset_column_information unless respond_to?(:parent_id)

    # Check parent_id dynamically with self.class.reset_column_information backup
    current_parent_id = respond_to?(:parent_id) ? parent_id : nil

    if current_parent_id.nil?
      # Top-level message → broadcast to main chat timeline
      broadcast_append_to [course, :chat],
                          target: "chat-messages",
                          partial: "discussion_messages/lumina_message",
                          locals: {
                            message: self,
                            previous_message: course.discussion_messages
                                                     .top_level
                                                     .where("id < ?", id)
                                                     .order(id: :desc)
                                                     .first,
                            course:
                          }
    else
      # Reply → append to thread panel + refresh parent reply count badge
      broadcast_append_to [course, :thread, current_parent_id],
                          target: "thread-replies-#{current_parent_id}",
                          partial: "discussion_message_replies/reply",
                          locals: { reply: self, course: }
      broadcast_replace_to [course, :chat],
                           target: "msg-replies-badge-#{current_parent_id}",
                           partial: "discussion_messages/replies_badge",
                           locals: { message: parent.reload, course: }
    end
  end

  after_destroy_commit do
    broadcast_remove_to [course, :chat]
  end

  scope :recent_window, ->(limit = 100) { order(created_at: :desc).limit(limit) }

  def author_name
    user&.name || I18n.t("notifications.common.anonymous")
  end

  def author_initial
    author_name[0]&.upcase || "?"
  end

  def instructor_message?
    user&.instructor? && course&.created_by == user_id
  end

  # Check if this message is from the same author as the previous one
  # and within 5 minutes - used for message grouping in the UI
  def same_group_as? other
    return false if other.nil?

    user_id == other.user_id &&
      (created_at - other.created_at).abs < 5.minutes
  end

  def earliest_replier_users(limit = 5)
    replies.includes(:user).chronological.map(&:user).compact.uniq.take(limit)
  end

  def last_reply_time_info
    last_reply = replies.chronological.last
    return nil if last_reply.nil?

    time = last_reply.created_at.in_time_zone("Hanoi")
    time_str = time.strftime("%I:%M %p")

    if time.to_date == Date.today
      "Last reply today at #{time_str}"
    elsif time.to_date == Date.yesterday
      "Last reply yesterday at #{time_str}"
    else
      day_num = time.day
      suffix = case day_num
               when 1, 21, 31 then "st"
               when 2, 22 then "nd"
               when 3, 23 then "rd"
               else "th"
               end
      formatted_date = time.strftime("%B %-d") + suffix
      "Last reply on #{formatted_date} at #{time_str}"
    end
  end

  def reactions_grouped_by_emoji
    reactions.includes(:user).group_by(&:emoji).map do |emoji, rxns|
      {
        emoji: emoji,
        count: rxns.size,
        users: rxns.map(&:user),
        user_ids: rxns.map(&:user_id)
      }
    end.sort_by { |r| -r[:count] }
  end
end
