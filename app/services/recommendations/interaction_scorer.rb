module Recommendations
  # Chuyen toan bo hanh vi cua user thanh diem.
  # Dung cho ContentFilter va CollaborativeFilter trong giai doan 2+.
  class InteractionScorer
    SCORES = {
      enrollment_active: 4.0,
      enrollment_pending: 2.0,
      enrollment_rejected: -2.0,
      review_5: 5.0,
      review_4: 3.0,
      review_3: 1.0,
      review_1_2: -2.0,   # negative signal
      wishlist: 3.0,
      cart: 2.0,
      note: 1.0,
      quiz_passed: 1.0
    }.freeze

    attr_reader :user

    def initialize(user)
      @user = user
    end

    def scores
      @scores ||= compute_scores
    end

    def enrolled_course_ids
      @enrolled_ids ||= user.enrollments.pluck(:course_id).to_set
    end

    def interaction_count
      @interaction_count ||= scores.count { |_course_id, score| !score.zero? }
    end

    def weights
      case
      when interaction_count >= 5 then { alpha: 0.50, beta: 0.35, gamma: 0.15 }
      when interaction_count >= 2 then { alpha: 0.20, beta: 0.50, gamma: 0.30 }
      else { alpha: 0.00, beta: 0.30, gamma: 0.70 }
      end
    end

    private

    def compute_scores
      scores = Hash.new(0.0)

      user.enrollments.each do |e|
        case e.status.to_s.to_sym
        when :active   then scores[e.course_id] += SCORES[:enrollment_active]
        when :pending  then scores[e.course_id] += SCORES[:enrollment_pending]
        when :rejected then scores[e.course_id] += SCORES[:enrollment_rejected]
        end
      end

      user.reviews.each do |r|
        course_id = r.course_id
        case r.rating
        when 5   then scores[course_id] += SCORES[:review_5]
        when 4   then scores[course_id] += SCORES[:review_4]
        when 3   then scores[course_id] += SCORES[:review_3]
        when 1, 2 then scores[course_id] += SCORES[:review_1_2]
        end
      end

      user.wishlists.each do |w|
        scores[w.course_id] += SCORES[:wishlist]
      end

      user.cart&.cart_items&.each do |ci|
        scores[ci.course_id] += SCORES[:cart]
      end

      user.notes.where.not(course_id: nil).find_each do |note|
        scores[note.course_id] += SCORES[:note]
      end

      user.quiz_attempts.completed.includes(:quiz).find_each do |attempt|
        next unless attempt.score.to_f >= 70

        scores[attempt.quiz.course_id] += SCORES[:quiz_passed]
      end

      scores
    end
  end
end
