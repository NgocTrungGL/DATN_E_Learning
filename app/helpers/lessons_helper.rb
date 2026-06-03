module LessonsHelper
  YOUTUBE_URL_REGEX = %r{
    (?:
      youtube(?:-nocookie)?\.com/
      (?:[^/\n\s]+/\S+/|
         (?:v|e(?:mbed)?)/|
         \S*?[?&]v=)
      | youtu\.be/
    )
    ([a-zA-Z0-9_-]{11})
  }x

  def youtube_embed_url url
    return nil if url.blank?

    match = url.match(YOUTUBE_URL_REGEX)
    return unless match && match[1]

    "https://www.youtube.com/embed/#{match[1]}"
  end

  def youtube_video_id url
    return nil if url.blank?

    match = url.match(YOUTUBE_URL_REGEX)
    match[1] if match
  end
end
