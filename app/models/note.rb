class Note < ApplicationRecord
  belongs_to :user
  belongs_to :lesson
  belongs_to :course

  validates :content, presence: true

  before_validation :set_course_from_lesson

  scope :recent, ->{ order(updated_at: :desc) }

  private

  def set_course_from_lesson
    self.course_id ||= lesson&.course&.id
  end
end
