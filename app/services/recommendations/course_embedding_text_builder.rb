require "digest"

module Recommendations
  class CourseEmbeddingTextBuilder
    attr_reader :course

    def initialize(course)
      @course = course
    end

    def text
      [
        "Title: #{course.title}",
        "Category: #{course.category&.name}",
        "Description: #{course.description}",
        learning_outcomes_text,
        modules_text,
        lessons_text
      ].compact_blank.join("\n")
    end

    def content_hash
      Digest::SHA256.hexdigest(text)
    end

    private

    def learning_outcomes_text
      outcomes = course.course_learning_outcomes.order(:order_index).pluck(:content)
      return if outcomes.empty?

      "Learning outcomes: #{outcomes.join('. ')}"
    end

    def modules_text
      modules = course.course_modules.order(:order_index).pluck(:title)
      return if modules.empty?

      "Modules: #{modules.join('. ')}"
    end

    def lessons_text
      lessons = course.lessons.order(:order_index).limit(80).pluck(:title)
      return if lessons.empty?

      "Lessons: #{lessons.join('. ')}"
    end
  end
end
