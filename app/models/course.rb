class Course < ApplicationRecord
  belongs_to :category, optional: true
  belongs_to :creator, class_name: User.name, foreign_key: "created_by",
optional: true
  has_many :course_modules, dependent: :destroy
  has_many :lessons, through: :course_modules
  has_many :enrollments, dependent: :restrict_with_error
  has_many :enrolled_users, through: :enrollments, source: :user
  has_many :reviews, dependent: :destroy
  has_many :quizzes, dependent: :destroy
  has_many :questions, dependent: :nullify
  has_many :progress_trackings, dependent: :destroy
  has_many :licenses, dependent: :destroy
  has_one_attached :image
  enum status: {
    draft: 0,
    pending: 1,
    published: 2,
    rejected: 3
  }

  scope :available, ->{where(status: :published)}
  # Validation
  validates :title, presence: true
  validates :price, numericality: {greater_than_or_equal_to: 0}
  scope :recent, ->{order(created_at: :desc)}
  def free?
    price.to_f.zero?
  end
end
