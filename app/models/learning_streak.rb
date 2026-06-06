class LearningStreak < ApplicationRecord
  belongs_to :user

  def update_streak!(activity_date)
    activity_date = activity_date.to_date
    if last_activity_date.nil?
      update!(current_streak: 1, last_activity_date: activity_date, weekly_activity_days: 1)
    elsif activity_date == last_activity_date
      # cung ngay, khong lam gi
    elsif activity_date == last_activity_date + 1.day
      self.current_streak += 1
      self.weekly_activity_days += 1
      self.last_activity_date = activity_date
      save!
    elsif activity_date > last_activity_date + 1.day
      self.current_streak = 1
      self.last_activity_date = activity_date
      reset_weekly_activity!(activity_date)
      save!
    end
    update_longest_streak!
  end

  def reset_weekly_activity!(activity_date)
    self.weekly_activity_days = 1
  end

  def reset_weekly_if_new_week!(current_date)
    week_start = current_date.to_date.beginning_of_week
    if last_activity_date.present? && last_activity_date < week_start
      self.current_streak = 0
      self.weekly_activity_days = 0
      save!
    end
  end

  private

  def update_longest_streak!
    update!(longest_streak: current_streak) if current_streak > longest_streak
  end
end
