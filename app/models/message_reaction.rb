class MessageReaction < ApplicationRecord
  belongs_to :user
  belongs_to :discussion_message

  validates :emoji, presence: true
  validates :user_id, uniqueness: { scope: [:discussion_message_id, :emoji], message: "has already reacted with this emoji" }

  after_create_commit  :broadcast_reactions_update
  after_destroy_commit :broadcast_reactions_update

  private

  def broadcast_reactions_update
    # Reload discussion message to ensure the rendered list is completely fresh
    msg = discussion_message.reload
    
    broadcast_replace_to [msg.course, :chat],
                         target: "msg-reactions-#{msg.id}",
                         partial: "discussion_messages/reactions",
                         locals: { message: msg, course: msg.course }
  end
end
