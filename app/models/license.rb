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

  private

  def generate_code
    self.code = "LIC-#{SecureRandom.hex(4).upcase}"
  end
end
