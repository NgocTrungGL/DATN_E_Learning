class LicenseCheckoutFulfillmentService
  def initialize session
    @session = session
    @metadata = session.metadata
  end

  def call
    return existing_invoice if existing_invoice
    return unless license_checkout?
    return unless paid?

    organization = Organization.find_by(id: @metadata["organization_id"])
    course = Course.find_by(id: @metadata["course_id"])
    quantity = @metadata["quantity"].to_i
    return unless organization && course && quantity.positive?

    ActiveRecord::Base.transaction do
      invoice = Invoice.lock.find_by(stripe_session_id: @session.id)
      next invoice if invoice

      create_paid_invoice(organization, course, quantity)
    end
  end

  private

  def existing_invoice
    @existing_invoice ||= Invoice.find_by(stripe_session_id: @session.id)
  end

  def license_checkout?
    @metadata["purchase_type"] == "license"
  end

  def paid?
    @session.payment_status == "paid"
  end

  def create_paid_invoice organization, course, quantity
    unit_price = @session.amount_total.to_i / quantity
    invoice = LicensePurchaseService.new(
      organization,
      course,
      quantity,
      unit_price,
      expires_at: 1.year.from_now
    ).call

    invoice&.update!(
      stripe_session_id: @session.id,
      stripe_payment_intent: @session.payment_intent,
      status: :paid,
      paid_at: Time.current
    )

    invoice
  end
end
