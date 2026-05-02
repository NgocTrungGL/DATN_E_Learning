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
  has_many :coupons, dependent: :destroy
  has_many :discussion_posts, dependent: :destroy
  has_many :discussion_messages, dependent: :destroy
  has_one_attached :image
  enum status: {
    draft: 0,
    pending: 1,
    published: 2,
    rejected: 3
  }
  def total_students
    enrollments.active.count
  end
  scope :available, ->{where(status: :published)}
  # Validation
  validates :title, presence: true
  validates :price, numericality: {greater_than_or_equal_to: 0}
  scope :recent, ->{order(created_at: :desc)}
  scope :min_rating_filter, ->(rating) {
    return all if rating.blank?
    where(id: Review.group(:course_id).having("AVG(rating) >= ?", rating).select(:course_id))
  }
  scope :price_filter, ->(type) {
    case type
    when "free" then where(price: 0)
    when "paid" then where("price > 0")
    else all
    end
  }

  def self.ransackable_attributes(auth_object = nil)
    ["title", "description", "price", "category_id", "created_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["category", "creator"]
  end

  def self.ransackable_scopes(auth_object = nil)
    [:min_rating_filter, :price_filter]
  end

  def free?
    price.to_f.zero?
  end

  def current_global_coupon
    return nil unless allow_admin_discounts?

    # Find the best valid global coupon
    Coupon.global.valid.order(discount_value: :desc).first
  end

  def discounted_price
    coupon = current_global_coupon
    return price if coupon.nil?

    if coupon.percentage?
      (price * (1 - coupon.discount_value / 100.0)).to_i
    else
      [price - coupon.discount_value, 0].max.to_i
    end
  end

  def has_discount?
    current_global_coupon.present?
  end

  def discount_label
    coupon = current_global_coupon
    return nil if coupon.nil?

    coupon.percentage? ? "-#{coupon.discount_value.to_i}%" : "-#{ActionController::Base.helpers.number_to_currency(coupon.discount_value, unit: "₫", precision: 0)}"
  end
end
