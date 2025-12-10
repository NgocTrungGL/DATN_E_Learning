class Lesson < ApplicationRecord
  belongs_to :course_module

  has_one :course, through: :course_module

  validates :title, presence: true

  default_scope{order(order_index: :asc)}
  has_many :comments, dependent: :destroy
  has_many :quizzes, dependent: :destroy
  has_many :questions, dependent: :nullify
  has_many :progress_trackings, dependent: :nullify
end
