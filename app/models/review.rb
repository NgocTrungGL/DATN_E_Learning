class Review < ApplicationRecord
  belongs_to :user
  belongs_to :course

  validates :content, presence: true
  validates :rating, presence: true, inclusion: {in: 1..5}

  scope :recent, ->{order(created_at: :desc)}
end
