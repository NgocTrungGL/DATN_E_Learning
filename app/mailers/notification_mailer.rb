class NotificationMailer < ApplicationMailer
  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.notification_mailer.notify.subject
  #
  def notify notification
    @notification = notification
    @user = notification.user

    mail(to: @user.email, subject: "[E-Learning] #{@notification.title}")
  end
end
