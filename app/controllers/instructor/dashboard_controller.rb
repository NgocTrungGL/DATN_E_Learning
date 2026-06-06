class Instructor::DashboardController < Instructor::BaseController
  def index
    @courses = current_user.created_courses

    # ── KPI Counts ────────────────────────────────────────────
    @published_count = @courses.published.count
    @pending_count = @courses.pending.count
    @draft_count = @courses.draft.count

    # ── Key Metrics ───────────────────────────────────────────
    @total_students = @courses.joins(:enrollments).distinct.count(:user_id)
    @total_revenue = current_user.wallet&.wallet_transactions
                                &.where(transaction_type: :sale_commission)
                                &.sum(:amount) || 0
    @avg_rating = @courses.joins(:reviews).average("reviews.rating").to_f.round(1)

    # Avg completion rate (from progress_trackings)
    total_lessons = @courses.published.joins(:lessons).count
    completed_lessons = ProgressTracking.joins(:course)
                                       .where(courses: { created_by: current_user.id })
                                       .where(progress_type: "lesson", status: "completed")
                                       .count
    @avg_completion = if total_lessons > 0
                        ((completed_lessons.to_f / total_lessons) * 100).round
                      else
                        0
                      end

    # ── Chart: Revenue last 30 days ───────────────────────────
    revenue_rows = current_user.wallet&.wallet_transactions
                              &.where(transaction_type: :sale_commission)
                              &.where("created_at >= ?", 30.days.ago)
                              &.pluck(:created_at, :amount) || []
    @revenue_chart_data = {}
    revenue_rows.each do |date, amount|
      key = date.in_time_zone("Asia/Bangkok").strftime("%d %b")
      @revenue_chart_data[key] = (@revenue_chart_data[key] || 0) + amount.to_f
    end

    # ── Chart: Enrollments last 30 days ───────────────────────
    enrollment_rows = Enrollment.joins(:course)
                             .where(course: { created_by: current_user.id })
                             .where("enrollments.created_at >= ?", 30.days.ago)
                             .pluck(:created_at)
    @enrollment_chart_data = {}
    enrollment_rows.each do |date|
      key = date.in_time_zone("Asia/Bangkok").strftime("%d %b")
      @enrollment_chart_data[key] = (@enrollment_chart_data[key] || 0) + 1
    end

    # ── Chart: Students by course ──────────────────────────────
    @course_students_data = @courses.published.joins(:enrollments)
                                    .group("courses.title")
                                    .count(:user_id)

    # ── Comparison: this month vs last month ──────────────────
    thirty_days_ago = 30.days.ago
    sixty_days_ago = 60.days.ago

    @revenue_this_month = current_user.wallet&.wallet_transactions
                                     &.where(transaction_type: :sale_commission)
                                     &.where("created_at >= ?", thirty_days_ago)
                                     &.sum(:amount) || 0

    @revenue_last_month = current_user.wallet&.wallet_transactions
                                      &.where(transaction_type: :sale_commission)
                                      &.where(created_at: sixty_days_ago...thirty_days_ago)
                                      &.sum(:amount) || 0

    @revenue_change = if @revenue_last_month.to_f > 0
                         ((@revenue_this_month - @revenue_last_month) / @revenue_last_month * 100).round
                       else
                         @revenue_this_month > 0 ? 100 : 0
                       end

    @students_this_month = Enrollment.joins(:course)
                                     .where(course: { created_by: current_user.id })
                                     .where("enrollments.created_at >= ?", thirty_days_ago)
                                     .count

    @students_last_month = Enrollment.joins(:course)
                                     .where(course: { created_by: current_user.id })
                                     .where(created_at: sixty_days_ago...thirty_days_ago)
                                     .count

    @students_change = if @students_last_month > 0
                         ((@students_this_month - @students_last_month) * 100 / @students_last_month).round
                       else
                         @students_this_month > 0 ? 100 : 0
                       end

    # ── Top course ────────────────────────────────────────────
    @top_course = @courses.published
                           .joins(:enrollments)
                           .group("courses.id")
                           .order(Arel.sql("COUNT(enrollments.id) DESC"))
                           .first
  end
end
