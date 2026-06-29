require "test_helper"

class Recommendations::InteractionScorerTest < Minitest::Test
  def test_weights_use_unique_scored_courses
    scorer = Recommendations::InteractionScorer.allocate
    scorer.define_singleton_method(:scores) do
      { 1 => 4.0, 2 => 3.0, 3 => -2.0, 4 => 1.0, 5 => 2.0 }
    end

    assert_equal({ alpha: 0.50, beta: 0.35, gamma: 0.15 },
                 scorer.weights)
  end

  def test_zero_score_does_not_count_as_an_interaction
    scorer = Recommendations::InteractionScorer.allocate
    scorer.define_singleton_method(:scores) do
      { 1 => 4.0, 2 => -2.0, 3 => 0.0 }
    end

    assert_equal 2, scorer.interaction_count
    assert_equal({ alpha: 0.20, beta: 0.50, gamma: 0.30 },
                 scorer.weights)
  end
end
