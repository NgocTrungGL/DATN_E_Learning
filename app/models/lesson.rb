class Lesson < ApplicationRecord
  belongs_to :course_module

  has_one :course, through: :course_module

  validates :title, presence: true

  enum lesson_type: { video: 0, text: 1 }, _default: :video
  enum upload_type: { link: 0, cloudinary: 1 }, _default: :link

  # Upload type LINK: video + document as URL strings
  # Upload type CLOUDINARY: video + documents as attached files
  has_rich_text :content
  has_one_attached :video_file
  has_one_attached :document_file  # For cloudinary upload mode
  has_many_attached :attachments  # Multiple files

  default_scope{order(order_index: :asc)}
  has_many :comments, dependent: :destroy
  has_many :quizzes, dependent: :destroy
  has_many :questions, dependent: :nullify
  has_many :progress_trackings, dependent: :nullify
  has_many :notes, dependent: :destroy

  def video?
    lesson_type == 'video' || lesson_type.nil?
  end

  def text?
    lesson_type == 'text'
  end

  def cloudinary_video?
    upload_type == 'cloudinary' && video_file.attached?
  end

  def cloudinary_video_url
    return nil unless cloudinary_video?

    video_file.blob.service.url(video_file.blob.key)
  end

  def link?
    upload_type == 'link'
  end

  def cloudinary?
    upload_type == 'cloudinary'
  end
end
