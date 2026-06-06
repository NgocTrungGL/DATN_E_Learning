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

  # Design system colors for use in views
  def ds_primary
    "#2563eb"
  end

  def ds_accent
    "#0d9488"
  end

  def ds_success
    "#10b981"
  end

  def ds_warning
    "#f59e0b"
  end

  def ds_danger
    "#ef4444"
  end

  def ds_text_muted
    "#94a3b8"
  end

  def ds_primary_light
    "#eff6ff"
  end

  def ds_accent_light
    "rgba(13, 148, 136, 0.1)"
  end
end
