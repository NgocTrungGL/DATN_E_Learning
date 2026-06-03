module Recommendations
  # Ghep diem tu 3 thuat toan.
  class ScoreFuser
    attr_reader :cf_results, :content_results, :popular_results

    def initialize(cf_results:, content_results:, popular_results:)
      @cf_results = cf_results
      @content_results = content_results
      @popular_results = popular_results
    end

    def fuse(alpha:, beta:, gamma:, limit: 20)
      score_map = Hash.new do |h, k|
        h[k] = { cf: 0.0, content: 0.0, popular: 0.0, course: nil }
      end

      max_cf = max_score(cf_results)
      max_content = max_score(content_results)
      max_pop = max_score(popular_results)

      cf_results.each do |r|
        score_map[r.course_id][:cf] = normalize(r.score, max_cf)
        score_map[r.course_id][:course] = r.course
      end

      content_results.each do |r|
        score_map[r.course_id][:content] = normalize(r.score, max_content)
        score_map[r.course_id][:course] ||= r.course
      end

      popular_results.each do |r|
        score_map[r.course_id][:popular] = normalize(r.score, max_pop)
        score_map[r.course_id][:course] ||= r.course
      end

      score_map.map do |course_id, scores|
        fused = alpha * scores[:cf] +
                beta  * scores[:content] +
                gamma * scores[:popular]

        reason = dominant_reason(scores)
        Recommendations::Result.new(
          course_id: course_id,
          course: scores[:course],
          score: fused.round(4),
          reason_type: reason
        )
      end.sort_by { |r| -r.score }.take(limit)
    end

    private

    def max_score(results)
      results.map(&:score).max.to_f.nonzero? || 1.0
    end

    def normalize(score, max)
      return 0.0 if max.zero?
      score / max
    end

    def dominant_reason(scores)
      sorted = scores.except(:course).sort_by { |_, v| -v }
      sorted.first&.first&.to_s || "popular"
    end
  end
end
