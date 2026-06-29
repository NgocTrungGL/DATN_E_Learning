require "test_helper"

class StudyPlanServiceTest < Minitest::Test
  def test_deadline_counts_only_preferred_study_days
    monday = Date.new(2026, 6, 22)

    deadline = StudyPlanService.send(
      :date_after_study_days,
      [1, 3, 5],
      from_date: monday,
      study_days: 4
    )

    assert_equal Date.new(2026, 6, 29), deadline
  end

  def test_blank_day_is_not_treated_as_available
    profile = { preferred_days: [1, 3, 5] }
    preferred_times = { "monday" => ["19:00-21:00"] }
    tuesday = Date.new(2026, 6, 23)

    refute StudyPlanService.send(
      :is_preferred_day?, tuesday, preferred_times, profile
    )
  end

  def test_start_times_include_minutes_already_scheduled
    monday = Date.new(2026, 6, 22)
    preferred_times = { "monday" => ["19:00-21:00"] }

    start_time = StudyPlanService.send(
      :determine_start_time, monday, preferred_times, 45
    )

    assert_equal [19, 45], [start_time.hour, start_time.min]
  end

  def test_slow_learning_history_increases_duration_estimate
    profile = { avg_lesson_duration: 1_800 }

    factor = StudyPlanService.send(:calculate_speed_factor, profile)

    assert_equal 2.0, factor
  end
end
