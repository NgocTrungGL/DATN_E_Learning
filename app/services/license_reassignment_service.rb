class LicenseReassignmentService
  def initialize(license, from_user, to_user = nil)
    @license = license
    @from_user = from_user
    @to_user = to_user
    @errors = []
  end

  def call
    return false unless valid?

    ActiveRecord::Base.transaction do
      # Remove enrollment from old user
      remove_enrollment(@from_user)

      # Update license
      @license.update!(
        user: @to_user,
        status: @to_user ? :assigned : :available
      )

      # Create enrollment for new user if assigned
      create_enrollment(@to_user) if @to_user
    end

    true
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "[LicenseReassignmentService] Failed: #{e.message}"
    false
  end

  def errors
    @errors
  end

  private

  def valid?
    unless @license.assigned?
      @errors << "License is not currently assigned."
      return false
    end

    if @to_user && @to_user.organization_id != @license.organization_id
      @errors << "Target user does not belong to the same organization."
      return false
    end

    true
  end

  def remove_enrollment(user)
    return unless user

    enrollment = Enrollment.find_by(user:, course: @license.course)
    return unless enrollment

    enrollment.destroy!
  end

  def create_enrollment(user)
    return unless user

    enrollment = Enrollment.find_or_initialize_by(user:, course: @license.course)
    enrollment.update!(
      price: @license.price,
      status: :active,
      enrolled_at: enrollment.enrolled_at || Time.current
    )
  end
end
