class LicensePurchaseService
  def initialize(organization, course, quantity, unit_price, expires_at: nil)
    @organization = organization
    @course = course
    @quantity = quantity
    @unit_price = unit_price
    @expires_at = expires_at
    @created_licenses = []
  end

  def call
    ActiveRecord::Base.transaction do
      invoice = Invoice.create!(
        organization: @organization,
        course: @course,
        quantity: @quantity,
        unit_price: @unit_price,
        total_amount: @unit_price * @quantity,
        status: :pending
      )

      @quantity.times do
        license = License.create!(
          organization: @organization,
          course: @course,
          status: :available,
          price: @unit_price,
          expires_at: @expires_at,
          invoice: invoice
        )
        @created_licenses << license
      end

      invoice
    end
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "[LicensePurchaseService] Failed: #{e.message}"
    nil
  end

  def licenses
    @created_licenses
  end
end
