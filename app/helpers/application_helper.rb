module ApplicationHelper
  include Pagy::Frontend
  def bootstrap_class_for flash_type
    case flash_type.to_sym
    when :notice
      "success"
    when :alert
      "danger"
    else
      "info"
    end
  end

  def wishlisted? course
    return false unless user_signed_in?

    current_user.wishlists.exists?(course_id: course.id)
  end

  def notes_count(lesson)
    current_user.notes.where(lesson:).count
  end
end
