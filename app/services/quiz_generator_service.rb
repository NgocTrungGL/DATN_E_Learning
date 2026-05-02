class QuizGeneratorService
  def initialize quiz_attempt
    @attempt = quiz_attempt
    @quiz = quiz_attempt.quiz
  end

  def call
    @attempt.quiz_answers.destroy_all

    questions = if @quiz.manual_selection?
                  fetch_manual_questions
                else
                  fetch_random_questions
                end

    questions.each do |question|
      @attempt.quiz_answers.create!(
        question:,
        selected_option_ids: []
      )
    end
  end

  private

  def fetch_manual_questions
    @quiz.questions.order("quiz_questions.order_index ASC")
  end

  def fetch_random_questions
    scope = Question.where(course_id: @quiz.course_id)

    easy_qs = scope.easy.order("RAND()").limit(@quiz.easy_count)
    medium_qs = scope.medium.order("RAND()").limit(@quiz.medium_count)
    hard_qs = scope.hard.order("RAND()").limit(@quiz.hard_count)

    (easy_qs + medium_qs + hard_qs).shuffle
  end
end
