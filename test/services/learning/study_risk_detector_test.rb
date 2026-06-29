require "test_helper"

class Learning::StudyRiskDetectorTest < Minitest::Test
  def test_on_track_profile_has_low_risk
    risk = detect(overdue_items_count: 0, inactive_days: 1,
                  skipped_items_count: 0, in_progress_items_count: 0,
                  required_daily_minutes: 30, daily_capacity_minutes: 60)

    assert_equal :on_track, risk.level
    assert_equal "On track", risk.label
  end

  def test_overdue_and_inactive_profile_is_at_risk
    risk = detect(overdue_items_count: 5, inactive_days: 8,
                  skipped_items_count: 1, in_progress_items_count: 1,
                  required_daily_minutes: 90, daily_capacity_minutes: 30)

    assert_equal :at_risk, risk.level
    assert_operator risk.score, :>=, 50
    assert risk.reasons.any? { |reason| reason.include?("overdue") }
  end

  def test_workload_above_capacity_creates_attention_reason
    risk = detect(overdue_items_count: 0, inactive_days: 1,
                  skipped_items_count: 0, in_progress_items_count: 0,
                  required_daily_minutes: 90, daily_capacity_minutes: 60)

    assert_equal :needs_attention, risk.level
    assert risk.reasons.any? { |reason| reason.include?("current study pace") }
  end

  private

  def detect(**attributes)
    defaults = {
      overdue_items_count: 0,
      inactive_days: 0,
      skipped_items_count: 0,
      in_progress_items_count: 0,
      required_daily_minutes: 0,
      daily_capacity_minutes: 60
    }
    profile = Struct.new(*defaults.keys, keyword_init: true).new(**defaults.merge(attributes))

    Learning::StudyRiskDetector.new(profile).call
  end
end
