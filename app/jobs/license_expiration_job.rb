class LicenseExpirationJob < ApplicationJob
  queue_as :default

  def perform(license)
    user = license.user
    organization = license.organization

    return unless user && organization

    Notification.create!(
      user: user,
      title: "License expired",
      body: "Your license for '#{license.course.title}' has expired.",
      notification_type: :license_expired,
      notifiable: license
    )

    organization.company_admins.each do |admin|
      Notification.create!(
        user: admin,
        title: "Employee lost license",
        body: "#{user.name} has lost license for '#{license.course.title}'.",
        notification_type: :license_expired,
        notifiable: license
      )
    end
  end
end
