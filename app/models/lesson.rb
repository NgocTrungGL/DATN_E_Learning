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
  has_many :study_plan_items, dependent: :destroy

  # Tu dong fetch YouTube duration khi video_url thay doi
  after_save :fetch_youtube_duration, if: :should_fetch_youtube_duration?
  # Tu dong sync duration tu Cloudinary blob metadata khi video_file attach
  after_save :sync_cloudinary_duration, if: :should_sync_cloudinary_duration?

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

  # Lay duration (tinh bang phut, lam tron len)
  # VD: 4.3 phut -> 5, 5.0 phut -> 5
  def duration_minutes
    return 0 if cached_duration_seconds.blank? || cached_duration_seconds.zero?

    (cached_duration_seconds.to_f / 60).ceil
  end

  # Dinh dang duration thanh chuoi
  # VD: "5m", "1h 30m"
  def formatted_duration
    return nil if cached_duration_seconds.blank? || cached_duration_seconds.zero?

    total_minutes = duration_minutes
    return nil if total_minutes.zero?

    hours = total_minutes / 60
    mins = total_minutes % 60

    if hours.positive?
      mins.positive? ? "#{hours}h #{mins}m" : "#{hours}h"
    else
      "#{mins}m"
    end
  end

  private

  # Kiem tra xem co can sync Cloudinary duration khong
  # Chi sync khi: cloudinary mode, co video_file attach, va chua co duration
  def should_sync_cloudinary_duration?
    cloudinary? && video_file.attached? &&
      (cached_duration_seconds.blank? || cached_duration_seconds.zero?)
  end

  # Doc duration tu blob metadata cua Cloudinary va cap nhat cached_duration_seconds
  def sync_cloudinary_duration
    blob = video_file.blob
    duration = blob&.metadata&.dig("cloudinary_duration")
    return if duration.blank? || duration.to_i.zero?

    update_column(:cached_duration_seconds, duration.to_i)
  rescue StandardError => e
    Rails.logger.warn "[Lesson] Failed to sync Cloudinary duration: #{e.message}"
  end

  # Kiem tra xem co can fetch YouTube duration khong
  # Chi fetch khi: link mode, co video_url, va video_url thay doi
  def should_fetch_youtube_duration?
    link? && video_url.present? && (video_url_changed? || cached_duration_seconds.nil? || cached_duration_seconds.zero?)
  end

  # Fetch va cache YouTube duration
  def fetch_youtube_duration
    return if video_url.blank?

    seconds = YoutubeDurationService.fetch_seconds(video_url)
    update_column(:cached_duration_seconds, seconds) if seconds > 0
  rescue StandardError => e
    Rails.logger.warn "[Lesson] Failed to fetch YouTube duration: #{e.message}"
  end
end
