class EmployeeImportService
  attr_reader :organization, :csv_data, :current_user

  def initialize(organization, csv_data, current_user)
    @organization = organization
    @csv_data = csv_data
    @current_user = current_user
    @results = { imported: [], failed: [] }
  end

  def call
    CSV.parse(@csv_data, headers: true, col_sep: ",").each do |row|
      import_row(row)
    end
    @results
  end

  private

  def import_row(row)
    email = row["email"]&.strip
    name = row["name"]&.strip
    phone = row["phone"]&.strip
    department = row["department"]&.strip

    if email.blank?
      @results[:failed] << { email: email, error: "Email is required" }
      return
    end

    if User.exists?(email: email)
      @results[:failed] << { email: email, error: "Email already exists in system" }
      return
    end

    user = User.create!(
      email: email,
      name: name.presence || email.split("@").first,
      phone: phone,
      password: SecureRandom.hex(8),
      role: :student,
      organization_id: @organization.id,
      confirmed_at: Time.current
    )

    if department.present?
      user.build_profile(department: department)
      user.profile.save
    end

    @results[:imported] << { email: email, user_id: user.id }
  end
end
