module NotificationsHelper
  def notification_icon type
    case type
    when "enrollment"
      "bi-journal-check"
    when "course_update"
      "bi-arrow-repeat"
    when "instructor_reply"
      "bi-reply"
    when "payment"
      "bi-credit-card"
    when "payout"
      "bi-wallet2"
    else
      "bi-info-circle"
    end
  end
end
