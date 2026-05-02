class InstructorProfile < ApplicationRecord
  belongs_to :user

  enum status: { pending: "pending", approved: "approved",
                 rejected: "rejected" }

  validates :cv_url, presence: true
  validates :linkedin_url, presence: true
end
