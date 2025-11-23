class Enrollment < ApplicationRecord
  belongs_to :user
  belongs_to :course

  enum status: {pending: "pending", active: "active", rejected: "rejected"}

  validates :user_id, uniqueness: {scope: :course_id}
end
