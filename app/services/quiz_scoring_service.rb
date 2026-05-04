class QuizScoringService
  WEIGHTS = { "easy" => 1, "medium" => 2, "hard" => 3 }.freeze

  def initialize quiz_attempt
    @attempt = quiz_attempt
    @quiz = quiz_attempt.quiz
  end

  def calculate!
    total_score = 0.0

    unit_value = calculate_unit_value

    @attempt.quiz_answers.includes(question: :question_options).each do |answer|
      question = answer.question

      max_points_for_question = if @quiz.weighted?
                                  unit_value * (WEIGHTS[question
                                  .difficulty] || 1)
                                else
                                  unit_value
                                end

      earned = calculate_answer_score(answer, max_points_for_question)

      answer.update_column(:score_earned, earned)
      total_score += earned
    end

    total_score
  end

  private

  def calculate_unit_value
    exam_scale = 100.0

    if @quiz.weighted?
      questions = @attempt.quiz_answers.map(&:question)
      total_weight = questions.sum{|q| WEIGHTS[q.difficulty] || 1}

      total_weight.zero? ? 0 : (exam_scale / total_weight)
    else
      count = @attempt.quiz_answers.count
      count.zero? ? 0 : (exam_scale / count)
    end
  end

  def calculate_answer_score answer, max_points
    question = answer.question
    user_ids = normalized_user_option_ids(answer)
    correct_ids = correct_option_ids(question)

    if question.single?
      return single_choice_score(user_ids, correct_ids,
                                 max_points)
    end
    if question.multiple?
      return multiple_choice_score(user_ids, correct_ids,
                                   max_points)
    end

    0.0
  end

  def normalized_user_option_ids answer
    Array(answer.selected_option_ids).map(&:to_i).uniq.sort
  end

  def correct_option_ids question
    question.question_options
            .select(&:is_correct)
            .map(&:id)
            .sort
  end

  def single_choice_score user_ids, correct_ids, max_points
    user_ids == correct_ids ? max_points : 0.0
  end

  def multiple_choice_score user_ids, correct_ids, max_points
    return 0.0 if contains_wrong_answer?(user_ids, correct_ids)
    return 0.0 if correct_ids.empty?

    partial_score(user_ids, correct_ids, max_points)
  end

  def contains_wrong_answer? user_ids, correct_ids
    (user_ids - correct_ids).any?
  end

  def partial_score user_ids, correct_ids, max_points
    matched_count = (user_ids & correct_ids).count
    (matched_count.to_f / correct_ids.count) * max_points
  end
end
