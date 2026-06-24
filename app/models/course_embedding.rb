class CourseEmbedding < ApplicationRecord
  belongs_to :course

  validates :embedding, presence: true
  validates :content_hash, presence: true
end
