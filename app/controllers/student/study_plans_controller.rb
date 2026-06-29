class Student::StudyPlansController < Student::BaseController
  before_action :set_study_plan,
                only: [:show, :edit, :update, :destroy, :pause, :resume,
                       :regenerate, :refresh_focus]
  before_action :set_enrolled_courses, only: [:new, :create]
  before_action :set_course, only: [:new, :create]

  def index
    @study_plans = current_user.study_plans
                               .includes(:course, :study_plan_items)
                               .order(created_at: :desc)
  end

  def show
    @grouped_items = @study_plan.study_plan_items
                                .includes(lesson: :course_module)
                                .order(:scheduled_date, :scheduled_start_time)
                                .group_by(&:scheduled_date)

    @learning_speed = StudyPlanService.learning_speed(current_user, @study_plan.course)
    @feasibility = StudyPlanService.feasibility_check(@study_plan)
    @behavior_profile = Learning::BehaviorProfileBuilder.new(
      current_user,
      course: @study_plan.course,
      study_plan: @study_plan
    ).call
    @study_risk = Learning::StudyRiskDetector.new(@behavior_profile).call
    @focus_recommendations = Learning::StudyFocusRecommender.new(@behavior_profile).call(limit: 5)
    @plan_suggestions = Learning::StudyPlanOptimizer.new(
      @behavior_profile,
      risk: @study_risk
    ).call(limit: 4)
  end

  def new
    prepare_plan_form
  end

  def create
    unless @course
      prepare_plan_form(plan_params)
      flash.now[:alert] = I18n.t("student.study_plans.invalid_course", default: "Please choose an available enrolled course.")
      render :new, status: :unprocessable_entity
      return
    end

    result = StudyPlanService.create_plan(
      user: current_user,
      course: @course,
      goal_deadline: plan_params[:goal_deadline],
      preferred_study_times: plan_params[:preferred_study_times]
    )

    if result
      redirect_to student_study_plan_path(result),
                  notice: I18n.t("student.study_plans.created", course_name: @course.title)
    else
      prepare_plan_form(plan_params)
      flash.now[:alert] = I18n.t("student.study_plans.cannot_create", default: "Could not create a study plan for this course.")
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @learning_speed = StudyPlanService.learning_speed(current_user, @study_plan.course)
    @study_plan.preferred_study_times = default_preferred_times if @study_plan.preferred_study_times.blank?
  end

  def update
    if @study_plan.update(plan_params)
      redirect_to student_study_plan_path(@study_plan),
                  notice: I18n.t("student.study_plans.updated")
    else
      @study_plan.preferred_study_times = default_preferred_times if @study_plan.preferred_study_times.blank?
      @learning_speed = StudyPlanService.learning_speed(current_user, @study_plan.course)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @study_plan.update!(status: :cancelled)
    redirect_to student_study_plans_path,
                notice: I18n.t("student.study_plans.cancelled")
  end

  def pause
    @study_plan.update!(status: :paused)
    redirect_to student_study_plan_path(@study_plan),
                notice: I18n.t("student.study_plans.paused")
  end

  def resume
    @study_plan.update!(status: :active)
    redirect_to student_study_plan_path(@study_plan),
                notice: I18n.t("student.study_plans.resumed")
  end

  def regenerate
    if @study_plan.active?
      # Create adjustment record
      StudyPlanAdjustment.create_for!(@study_plan, "system_replan")

      # Delete old items and reschedule
      @study_plan.study_plan_items.destroy_all
      StudyPlanService.schedule_lessons(@study_plan)

      redirect_to student_study_plan_path(@study_plan),
                  notice: I18n.t("student.study_plans.regenerated")
    else
      redirect_to student_study_plan_path(@study_plan),
                  alert: I18n.t("student.study_plans.cannot_regenerate")
    end
  end

  def refresh_focus
    redirect_to student_study_plan_path(@study_plan),
                notice: "Study focus suggestions were refreshed."
  end

  private

  def set_enrolled_courses
    @enrolled_courses = available_study_plan_courses
  end

  def set_study_plan
    @study_plan = current_user.study_plans.find(params[:id])
  end

  def set_course
    course_id = params.dig(:study_plan, :course_id) || params[:course_id]
    @course = @enrolled_courses.find_by(id: course_id) if course_id.present?
  end

  def prepare_plan_form(attributes = {})
    @study_plan = StudyPlan.new(attributes)
    @study_plan.preferred_study_times = default_preferred_times if @study_plan.preferred_study_times.blank?
    return unless @course

    @learning_speed = StudyPlanService.learning_speed(current_user, @course)
    @suggested_deadline = StudyPlanService.suggest_deadline(current_user, @course)
  end

  def available_study_plan_courses
    current_user.enrolled_courses.available
                .includes(:category, :creator, course_modules: :lessons)
                .where.not(id: current_user.study_plans.where(status: %i[active completed]).select(:course_id))
  end

  def plan_params
    params.fetch(:study_plan, ActionController::Parameters.new).permit(
      :course_id,
      :goal_deadline,
      :target_days,
      preferred_study_times: [:monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday]
    )
  end

  def default_preferred_times
    {
      monday: ["19:00-21:00"],
      tuesday: ["19:00-21:00"],
      wednesday: ["19:00-21:00"],
      thursday: ["19:00-21:00"],
      friday: ["19:00-21:00"],
      saturday: ["09:00-12:00", "14:00-17:00"],
      sunday: ["09:00-12:00", "14:00-17:00"]
    }
  end
end
