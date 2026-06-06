class Student::LearningGoalsController < Student::BaseController
  def index
    @goals = current_user.learning_goals.order(week_start: :desc).limit(8)
    @active_goal = current_user.active_goal
    @new_goal = LearningGoal.new
  end

  def create
    @goal = current_user.learning_goals.build(goal_params)
    @goal.week_start = Time.current.beginning_of_week.to_date
    @goal.is_active = true

    current_user.learning_goals.active
                .where(goal_type: @goal.goal_type)
                .update_all(is_active: false)

    if @goal.save
      redirect_to student_learning_goals_path, notice: "Da dat muc tieu thanh cong!"
    else
      @goals = current_user.learning_goals.order(week_start: :desc).limit(8)
      @active_goal = current_user.active_goal
      render :index, status: :unprocessable_entity
    end
  end

  def update
    @goal = current_user.learning_goals.find(params[:id])
    if @goal.update(goal_params)
      redirect_to student_learning_goals_path, notice: "Cap nhat muc tieu thanh cong!"
    else
      redirect_to student_learning_goals_path, alert: "Cap nhat that bai."
    end
  end

  def destroy
    @goal = current_user.learning_goals.find(params[:id])
    @goal.update!(is_active: false)
    redirect_to student_learning_goals_path, notice: "Da xoa muc tieu."
  end

  private

  def goal_params
    params.require(:learning_goal).permit(:goal_type, :target_value)
  end
end
