class Admin::QuizQuestionsController < Admin::BaseController
  before_action :set_quiz, only: [:create]
  before_action :set_quiz_question, only: [:destroy]

  # POST /admin/quizzes/:quiz_id/quiz_questions
  def create
    @quiz_question = @quiz.quiz_questions
                          .build(question_id: params[:question_id])

    if @quiz_question.save
      redirect_to admin_quiz_path(@quiz),
                  notice: t("admin.quiz_questions.create.success")
    else
      redirect_to admin_quiz_path(@quiz),
                  alert: @quiz_question.errors.full_messages.join(", ")
    end
  end

  # DELETE /admin/quiz_questions/:id
  def destroy
    @quiz = @quiz_question.quiz

    if @quiz_question.destroy
      redirect_to admin_quiz_path(@quiz),
                  notice: t("admin.quiz_questions.destroy.success")
    else
      redirect_to admin_quiz_path(@quiz),
                  alert: @quiz_question.errors.full_messages.to_sentence
    end
  end

  private

  def set_quiz
    @quiz = Quiz.find_by(id: params[:quiz_id]) ||
            render_not_found(admin_quizzes_path, t("admin.quiz_questions
            .not_found"))
  end

  def set_quiz_question
    @quiz_question = QuizQuestion.find_by(id: params[:id]) ||
                     render_not_found(admin_quiz_questions_path,
                                      t("admin.quiz_questions
                                      .question_not_found"))
  end
end
