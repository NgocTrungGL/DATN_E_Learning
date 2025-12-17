class Instructor::QuestionsController < Instructor::BaseController
  load_and_authorize_resource
  skip_load_resource only: :index

  def index
    @pagy, @questions = pagy(
      current_user.created_questions
                  .includes(:course, :lesson)
                  .order(created_at: :desc)
    )
  end

  def show; end

  def new
    (4 - @question.question_options.size).times do
      @question.question_options.build
    end

    load_my_courses
  end

  def create
    if @question.save
      redirect_to instructor_questions_path, notice: "Tạo câu hỏi thành công."
    else
      load_my_courses
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    (4 - @question.question_options.count).times do
      @question.question_options.build
    end
    load_my_courses
  end

  def update
    if @question.update(question_params)
      redirect_to instructor_questions_path, notice: "Cập nhật thành công."
    else
      load_my_courses
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @question.destroy
    redirect_to instructor_questions_path, notice: "Đã xóa câu hỏi."
  end

  private

  def load_my_courses
    @courses = current_user.created_courses.order(:title)
  end

  def question_params
    params.require(:question).permit(
      :question_text,
      :question_type,
      :difficulty,
      :course_id,
      :lesson_id,
      question_options_attributes: [:id, :option_text, :is_correct,
:_destroy]
    ).merge(created_by: current_user.id)
  end
end
