class License < ApplicationRecord
  belongs_to :organization
  belongs_to :course
  belongs_to :user, optional: true

  enum status: {
    available: 0,
    assigned: 1,
    expired: 2
  }

  before_create :generate_code

  scope :expiring_soon, -> {
    where("expires_at IS NOT NULL AND expires_at <= ? AND expires_at > ?", 7.days.from_now, Time.current)
      .where.not(status: :expired)
  }

  scope :expired_now, -> {
    where("expires_at IS NOT NULL AND expires_at <= ?", Time.current)
      .where.not(status: :expired)
  }

  def expired?
    expires_at.present? && (expires_at <= Time.current || status == :expired)
  end

  def expiring_soon?
    expires_at.present? &&
      expires_at <= 7.days.from_now &&
      expires_at > Time.current &&
      status != :expired
  end

  def self.expire_licenses!
    expired_now.find_each do |license|
      license.update!(status: :expired)
      LicenseExpirationJob.perform_later(license) if license.user_id?
    end
  end

  private

  def generate_code
    self.code = "LIC-#{SecureRandom.hex(4).upcase}"
  end
end
