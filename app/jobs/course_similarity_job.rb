class CourseSimilarityJob < ApplicationJob
  queue_as :low

  def perform
    enrollments = Enrollment.select(:user_id, :course_id).to_a
    return if enrollments.empty?

    # Build interaction matrix: course_id => { user_id => score }
    matrix = build_matrix(enrollments)

    # Compute cosine similarity for all course pairs
    course_ids = matrix.keys
    similarities = []

    course_ids.each do |a_id|
      course_ids.each do |b_id|
        next if a_id >= b_id

        sim = cosine_similarity(matrix[a_id], matrix[b_id])
        next if sim < 0.05

        now = Time.current
        similarities << { course_a_id: a_id, course_b_id: b_id, score: sim, computed_at: now, created_at: now, updated_at: now }
        similarities << { course_a_id: b_id, course_b_id: a_id, score: sim, computed_at: now, created_at: now, updated_at: now }
      end
    end

    return if similarities.empty?

    ActiveRecord::Base.transaction do
      CourseSimilarity.delete_all
      CourseSimilarity.insert_all(similarities)
    end
  end

  private

  def build_matrix(enrollments)
    matrix = Hash.new { |h, k| h[k] = Hash.new(0.0) }

    enrollments.each do |e|
      matrix[e.course_id][e.user_id] += 1.0
    end

    matrix
  end

  def cosine_similarity(vec_a, vec_b)
    shared_users = vec_a.keys & vec_b.keys
    return 0.0 if shared_users.empty?

    dot_product = shared_users.sum { |u| vec_a[u] * vec_b[u] }
    norm_a = Math.sqrt(vec_a.values.sum { |v| v * v })
    norm_b = Math.sqrt(vec_b.values.sum { |v| v * v })

    return 0.0 if norm_a.zero? || norm_b.zero?
    dot_product / (norm_a * norm_b)
  end
end
