class Invoice < ApplicationRecord
  belongs_to :organization
  belongs_to :course
  has_many :licenses, dependent: :nullify

  enum status: { pending: 0, paid: 1, failed: 2, refunded: 3 }

  before_validation :generate_invoice_number, on: :create

  scope :latest_first, -> { order(created_at: :desc) }

  def self.generate_number(org_id)
    prefix = "INV"
    year = Time.current.year
    count = where("invoice_number LIKE ?", "#{prefix}-#{year}-%").count + 1
    format("%s-%d-%05d", prefix, year, count)
  end

  private

  def generate_invoice_number
    self.invoice_number ||= Invoice.generate_number(organization_id)
  end
end
