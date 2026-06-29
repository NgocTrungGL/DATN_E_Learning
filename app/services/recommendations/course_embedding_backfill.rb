module Recommendations
  class CourseEmbeddingBackfill
    def initialize(client: EmbeddingClientFactory.build, scope: Course.published)
      @client = client
      @scope = scope
    end

    def call(limit: nil, force: false, sleep_seconds: 0)
      stats = { embedded: 0, skipped: 0, failed: 0 }
      courses = @scope.includes(:category, :course_learning_outcomes, :course_modules, :course_embedding)
      courses = courses.limit(limit) if limit.present?

      courses.find_each do |course|
        builder = CourseEmbeddingTextBuilder.new(course)
        existing = course.course_embedding

        if !force && existing&.content_hash == builder.content_hash
          stats[:skipped] += 1
          next
        end

        embedding = @client.embed(builder.text)
        record = existing || course.build_course_embedding
        record.update!(
          embedding: embedding,
          content_hash: builder.content_hash,
          embedded_at: Time.current
        )
        stats[:embedded] += 1
        sleep sleep_seconds.to_f if sleep_seconds.to_f.positive?
      rescue StandardError => e
        stats[:failed] += 1
        Rails.logger.error("[CourseEmbeddingBackfill] course_id=#{course.id} #{e.class}: #{e.message}")
      end

      stats
    end
  end
end
