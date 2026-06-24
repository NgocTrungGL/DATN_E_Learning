module Recommendations
  class OfflineEvaluator
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
        profile_interactions: split[:profile_interactions]
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
          .group("users.id")
          .having("COUNT(enrollments.id) >= 5")
          .order("users.id")
          .limit(user_limit)
    end

    def temporal_split(user)
      interactions = collect_positive_interactions(user)
      return if interactions.size < 3

      sorted = interactions.sort_by { |item| item[:created_at] || Time.zone.at(0) }
      ground_truth = sorted.last([2, (sorted.size * 0.25).ceil].min)
      history = sorted - ground_truth
      return if history.empty? || ground_truth.empty?

      profile = Hash.new(0.0)
      history.each { |item| profile[item[:course_id]] += item[:weight] }

      {
        profile_interactions: profile,
        ground_truth_ids: ground_truth.map { |item| item[:course_id] }.uniq
      }
    end

    def collect_positive_interactions(user)
      interactions = []

      user.enrollments.where("status IN (?)", %w[active completed]).find_each do |enrollment|
        interactions << {
          course_id: enrollment.course_id,
          weight: enrollment.status == "completed" ? AiEmbeddingFilter::WEIGHTS[:completed] : AiEmbeddingFilter::WEIGHTS[:active],
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
