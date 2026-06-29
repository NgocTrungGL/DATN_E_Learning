require "set"

module Recommendations
  class OfflineEvaluator
    SimilarityRecord = Struct.new(:course_a_id, :course_b_id, :score,
                                  keyword_init: true)
    DEFAULT_K = 5
    SEMANTIC_THRESHOLD = 0.80

    attr_reader :k, :user_limit

    def initialize(k: DEFAULT_K, user_limit: 200)
      @k = k
      @user_limit = user_limit
    end

    def call
      rows = evaluation_users.filter_map { |user| evaluate_user(user) }
      summarize(rows)
    end

    def evaluate_user(user)
      split = temporal_split(user)
      return if split.blank?

      hybrid_results = ProfileHybridFilter.new(
        profile_interactions: split[:profile_interactions],
        course_similarities: leave_one_user_out_similarities(
          user.id, split[:profile_interactions].keys, split[:training_cutoff]
        ),
        evaluation_user_id: user.id,
        training_cutoff: split[:training_cutoff]
      ).call(limit: k)

      ai_results = AiEmbeddingFilter.new(
        profile_interactions: split[:profile_interactions]
      ).call(limit: k)

      hybrid_relevance = relevance_details(hybrid_results, split[:ground_truth_ids])
      ai_relevance = relevance_details(ai_results, split[:ground_truth_ids])

      {
        user: user,
        profile_interactions: split[:profile_interactions],
        ground_truth_ids: split[:ground_truth_ids],
        hybrid_results: hybrid_results,
        ai_results: ai_results,
        hybrid_relevance: hybrid_relevance,
        ai_relevance: ai_relevance,
        hybrid_metrics: metrics(hybrid_results, split[:ground_truth_ids], hybrid_relevance),
        ai_metrics: metrics(ai_results, split[:ground_truth_ids], ai_relevance),
        overlap: overlap(hybrid_results, ai_results)
      }
    end

    private

    def evaluation_users
      User.where(role: "student")
          .joins(:enrollments)
          .where(enrollments: { status: "active" })
          .group("users.id")
          .having("COUNT(enrollments.id) >= 5")
          .order("users.id")
          .limit(user_limit)
    end

    def temporal_split(user)
      enrollments = user.enrollments.active.to_a.sort_by do |enrollment|
        enrollment.enrolled_at || enrollment.created_at
      end
      return if enrollments.size < 3

      ground_truth = enrollments.last([2, (enrollments.size * 0.25).ceil].min)
      ground_truth_ids = ground_truth.map(&:course_id).uniq
      training_cutoff = ground_truth.map do |enrollment|
        enrollment.enrolled_at || enrollment.created_at
      end.min
      history = collect_positive_interactions(user).select do |item|
        item[:created_at] < training_cutoff &&
          !ground_truth_ids.include?(item[:course_id])
      end
      return if history.empty? || ground_truth_ids.empty?

      profile = Hash.new(0.0)
      history.each { |item| profile[item[:course_id]] += item[:weight] }

      {
        profile_interactions: profile,
        ground_truth_ids: ground_truth_ids,
        training_cutoff: training_cutoff
      }
    end

    def collect_positive_interactions(user)
      interactions = []

      user.enrollments.active.find_each do |enrollment|
        interactions << {
          course_id: enrollment.course_id,
          weight: AiEmbeddingFilter::WEIGHTS[:active],
          created_at: enrollment.enrolled_at || enrollment.created_at
        }
      end

      user.wishlists.find_each do |wishlist|
        interactions << {
          course_id: wishlist.course_id,
          weight: AiEmbeddingFilter::WEIGHTS[:wishlist],
          created_at: wishlist.created_at
        }
      end

      user.reviews.where("rating >= ?", 4).find_each do |review|
        interactions << {
          course_id: review.course_id,
          weight: review.rating.to_i >= 5 ? AiEmbeddingFilter::WEIGHTS[:review_5] : AiEmbeddingFilter::WEIGHTS[:review_4],
          created_at: review.created_at
        }
      end

      interactions
    end

    def leave_one_user_out_similarities(user_id, source_course_ids, cutoff)
      course_users = Hash.new { |hash, key| hash[key] = Set.new }
      Enrollment.active
                .where.not(user_id: user_id)
                .where("COALESCE(enrolled_at, created_at) < ?", cutoff)
                .pluck(:user_id, :course_id)
                .each { |enrolled_user_id, course_id| course_users[course_id] << enrolled_user_id }

      source_course_ids.flat_map do |source_course_id|
        source_users = course_users[source_course_id]
        next [] if source_users.empty?

        course_users.filter_map do |candidate_course_id, candidate_users|
          next if candidate_course_id == source_course_id

          shared_count = (source_users & candidate_users).size
          next if shared_count.zero?

          score = shared_count.to_f /
                  Math.sqrt(source_users.size * candidate_users.size)
          next if score <= 0.05

          SimilarityRecord.new(course_a_id: source_course_id,
                               course_b_id: candidate_course_id,
                               score: score)
        end
      end
    end

    def relevance_details(results, ground_truth_ids)
      truth_courses = Course.where(id: ground_truth_ids).includes(:category).index_by(&:id)
      truth_category_ids = truth_courses.values.map(&:category_id).compact
      truth_parent_ids = Category.where(id: truth_category_ids).where.not(parent_id: nil).pluck(:parent_id)
      related_category_ids = (truth_category_ids | truth_parent_ids).compact
      truth_embeddings = CourseEmbedding.where(course_id: ground_truth_ids).pluck(:course_id, :embedding).to_h

      results.each_with_object({}) do |result, memo|
        semantic_score = max_semantic_score(result.course_id, truth_embeddings)
        exact = ground_truth_ids.include?(result.course_id)
        category = result.course&.category_id.present? && related_category_ids.include?(result.course.category_id)
        semantic = semantic_score >= SEMANTIC_THRESHOLD

        memo[result.course_id] = {
          exact: exact,
          category: category,
          semantic: semantic,
          semantic_score: semantic_score,
          soft: exact || category || semantic
        }
      end
    end

    def max_semantic_score(course_id, truth_embeddings)
      course_embedding = CourseEmbedding.find_by(course_id: course_id)&.embedding
      return 0.0 if course_embedding.blank? || truth_embeddings.empty?

      truth_embeddings.values.map do |truth_embedding|
        VectorMath.cosine_similarity(course_embedding, truth_embedding)
      end.max.to_f
    end

    def metrics(results, ground_truth_ids, relevance)
      result_ids = results.map(&:course_id)
      hits = result_ids & ground_truth_ids
      soft_hits = result_ids.select { |course_id| relevance.dig(course_id, :soft) }

      {
        exact_hit_rate: hits.any? ? 1.0 : 0.0,
        exact_precision: result_ids.empty? ? 0.0 : hits.size.to_f / result_ids.size,
        exact_recall: ground_truth_ids.empty? ? 0.0 : hits.size.to_f / ground_truth_ids.size,
        exact_ndcg: ndcg(result_ids, ground_truth_ids),
        soft_hit_rate: soft_hits.any? ? 1.0 : 0.0,
        soft_precision: result_ids.empty? ? 0.0 : soft_hits.size.to_f / result_ids.size,
        soft_recall: ground_truth_ids.empty? ? 0.0 : [soft_hits.size.to_f / ground_truth_ids.size, 1.0].min,
        soft_ndcg: soft_ndcg(result_ids, relevance),
        avg_semantic: average(result_ids.map { |course_id| relevance.dig(course_id, :semantic_score) })
      }
    end

    def ndcg(result_ids, ground_truth_ids)
      dcg = result_ids.each_with_index.sum do |course_id, index|
        ground_truth_ids.include?(course_id) ? 1.0 / Math.log2(index + 2) : 0.0
      end

      ideal_hits = [ground_truth_ids.size, result_ids.size].min
      idcg = (0...ideal_hits).sum { |index| 1.0 / Math.log2(index + 2) }
      return 0.0 if idcg.zero?

      dcg / idcg
    end

    def soft_ndcg(result_ids, relevance)
      dcg = result_ids.each_with_index.sum do |course_id, index|
        relevance.dig(course_id, :soft) ? 1.0 / Math.log2(index + 2) : 0.0
      end

      ideal_hits = result_ids.count { |course_id| relevance.dig(course_id, :soft) }
      idcg = (0...ideal_hits).sum { |index| 1.0 / Math.log2(index + 2) }
      return 0.0 if idcg.zero?

      dcg / idcg
    end

    def overlap(left_results, right_results)
      left_ids = left_results.map(&:course_id)
      right_ids = right_results.map(&:course_id)
      return 0.0 if left_ids.empty? && right_ids.empty?

      (left_ids & right_ids).size.to_f / (left_ids | right_ids).size
    end

    def summarize(rows)
      {
        evaluated_users: rows.size,
        k: k,
        embedded_courses: CourseEmbedding.count,
        published_courses: Course.published.count,
        hybrid: average_metrics(rows, :hybrid_metrics),
        ai_embedding: average_metrics(rows, :ai_metrics),
        overlap: average(rows.map { |row| row[:overlap] }),
        rows: rows
      }
    end

    def average_metrics(rows, key)
      {
        exact_hit_rate: average(rows.map { |row| row.dig(key, :exact_hit_rate) }),
        exact_precision: average(rows.map { |row| row.dig(key, :exact_precision) }),
        exact_recall: average(rows.map { |row| row.dig(key, :exact_recall) }),
        exact_ndcg: average(rows.map { |row| row.dig(key, :exact_ndcg) }),
        soft_hit_rate: average(rows.map { |row| row.dig(key, :soft_hit_rate) }),
        soft_precision: average(rows.map { |row| row.dig(key, :soft_precision) }),
        soft_recall: average(rows.map { |row| row.dig(key, :soft_recall) }),
        soft_ndcg: average(rows.map { |row| row.dig(key, :soft_ndcg) }),
        avg_semantic: average(rows.map { |row| row.dig(key, :avg_semantic) })
      }
    end

    def average(values)
      compact = values.compact
      return 0.0 if compact.empty?

      compact.sum.to_f / compact.size
    end
  end
end
