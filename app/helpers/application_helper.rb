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

  def format_vnd amount
    number_to_currency(amount || 0, unit: "VND", format: "%n %u", precision: 0, delimiter: ".")
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

  def instructor_line_chart_library
    instructor_base_chart_library.deep_merge(
      elements: {
        line: { tension: 0.38, borderWidth: 3 },
        point: { radius: 0, hoverRadius: 5, hitRadius: 8, borderWidth: 2 }
      },
      scales: {
        xAxes: [{
          gridLines: { display: false, drawBorder: false },
          ticks: { display: false }
        }]
      }
    )
  end

  def instructor_bar_chart_library
    instructor_base_chart_library.deep_merge(
      scales: {
        xAxes: [{
          gridLines: { color: instructor_chart_axis_color, drawBorder: false, zeroLineColor: instructor_chart_axis_color },
          ticks: { beginAtZero: true, fontColor: instructor_chart_tick_color, fontSize: 11, precision: 0 }
        }],
        yAxes: [{
          gridLines: { display: false, drawBorder: false },
          ticks: { fontColor: instructor_chart_tick_color, fontSize: 11 }
        }]
      }
    )
  end

  def admin_line_chart_library
    admin_base_chart_library.deep_merge(
      elements: {
        line: { tension: 0.38, borderWidth: 3 },
        point: { radius: 0, hoverRadius: 5, hitRadius: 8, borderWidth: 2 }
      },
      scales: {
        xAxes: [{
          gridLines: { display: false, drawBorder: false },
          ticks: { display: false }
        }]
      }
    )
  end

  def admin_bar_chart_library
    admin_base_chart_library.deep_merge(
      scales: {
        xAxes: [{
          gridLines: { color: admin_chart_axis_color, drawBorder: false, zeroLineColor: admin_chart_axis_color },
          ticks: { beginAtZero: true, fontColor: admin_chart_tick_color, fontSize: 11, precision: 0 }
        }],
        yAxes: [{
          gridLines: { display: false, drawBorder: false },
          ticks: { fontColor: admin_chart_tick_color, fontSize: 11 }
        }]
      }
    )
  end

  def admin_bar_chart_without_labels_library
    admin_base_chart_library.deep_merge(
      scales: {
        xAxes: [{
          gridLines: { display: false, drawBorder: false },
          ticks: { display: false }
        }],
        yAxes: [{
          gridLines: { color: admin_chart_axis_color, drawBorder: false, zeroLineColor: admin_chart_axis_color },
          ticks: { beginAtZero: true, fontColor: admin_chart_tick_color, fontSize: 11, precision: 0 }
        }]
      }
    )
  end

  private

  def instructor_base_chart_library
    {
      legend: { display: false },
      maintainAspectRatio: false,
      tooltips: {
        backgroundColor: "rgba(15, 23, 42, 0.94)",
        titleFontColor: "#ffffff",
        bodyFontColor: "#e2e8f0",
        borderColor: "rgba(255, 255, 255, 0.12)",
        borderWidth: 1,
        cornerRadius: 10,
        displayColors: false,
        xPadding: 12,
        yPadding: 10
      },
      scales: {
        xAxes: [{
          gridLines: { display: false, drawBorder: false },
          ticks: { fontColor: instructor_chart_tick_color, fontSize: 11, maxRotation: 0, autoSkip: true, maxTicksLimit: 8 }
        }],
        yAxes: [{
          gridLines: { color: instructor_chart_axis_color, drawBorder: false, zeroLineColor: instructor_chart_axis_color },
          ticks: { beginAtZero: true, fontColor: instructor_chart_tick_color, fontSize: 11, precision: 0 }
        }]
      }
    }
  end

  def instructor_chart_axis_color
    "rgba(148, 163, 184, 0.32)"
  end

  def instructor_chart_tick_color
    "#64748b"
  end

  def admin_base_chart_library
    {
      legend: { display: false },
      maintainAspectRatio: false,
      tooltips: {
        backgroundColor: "rgba(15, 23, 42, 0.94)",
        titleFontColor: "#ffffff",
        bodyFontColor: "#e2e8f0",
        borderColor: "rgba(255, 255, 255, 0.12)",
        borderWidth: 1,
        cornerRadius: 10,
        displayColors: false,
        xPadding: 12,
        yPadding: 10
      },
      scales: {
        xAxes: [{
          gridLines: { display: false, drawBorder: false },
          ticks: { fontColor: admin_chart_tick_color, fontSize: 11, maxRotation: 0, autoSkip: true, maxTicksLimit: 8 }
        }],
        yAxes: [{
          gridLines: { color: admin_chart_axis_color, drawBorder: false, zeroLineColor: admin_chart_axis_color },
          ticks: { beginAtZero: true, fontColor: admin_chart_tick_color, fontSize: 11, precision: 0 }
        }]
      }
    }
  end

  def admin_chart_axis_color
    "rgba(148, 163, 184, 0.32)"
  end

  def admin_chart_tick_color
    "#64748b"
  end
end
