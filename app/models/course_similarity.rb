class CourseSimilarity < ApplicationRecord
  belongs_to :course_a, class_name: "Course", foreign_key: :course_a_id
  belongs_to :course_b, class_name: "Course", foreign_key: :course_b_id
end
