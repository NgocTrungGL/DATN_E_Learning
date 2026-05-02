# rubocop:disable all
class Coupon < ApplicationRecord
  belongs_to :creator, class_name: "User"
  belongs_to :course, optional: true

  enum discount_type: { percentage: 0, fixed_amount: 1 }
  enum target_type: { global: 0, specific_course: 1 }
  enum status: { active: 0, inactive: 1 }

  validates :code, presence: true, uniqueness: { case_sensitive: false }
  validates :discount_value, presence: true, numericality: { greater_than: 0 }
  validates :start_at, presence: true
  validates :end_at, presence: true
  validate :end_at_after_start_at
  validate :start_at_not_in_past, on: :create
  validate :specific_course_requires_course_id

  scope :valid, lambda {    active.where("start_at <= ? AND end_at >= ?", Time.current, Time.current)
          .where("usage_limit = 0 OR usage_count < usage_limit")
  }

  def use!
    increment!(:usage_count) if usage_limit.zero? || usage_count < usage_limit
  end

  def expired?
    end_at < Time.current
  end

  def active_and_current?
    active? &&
      start_at <= Time.current &&
      end_at >= Time.current &&
      (usage_limit.zero? || usage_count < usage_limit)
  end

  private

  def end_at_after_start_at
    return if end_at.blank? || start_at.blank?

    return unless end_at <= start_at

    errors.add(:end_at, "phải sau thời gian bắt đầu")
  end

  def start_at_not_in_past
    return if start_at.blank?

    return unless start_at < Time.current - 1.minute

    errors.add(:start_at, "không được ở trong quá khứ")
  end

  def specific_course_requires_course_id
    return unless specific_course? && course_id.blank?

    errors.add(:course_id,
               "phải được chọn cho mã giảm giá riêng theo khóa học")
  end
end
