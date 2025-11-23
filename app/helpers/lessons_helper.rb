module LessonsHelper
  def youtube_embed_url url
    return nil if url.blank?

    regex = %r{(?:youtube(?:-nocookie)?\.com/(?:[^/\n\s]+/\S+/|(?:v|e(?:mbed)?)/|\S*?[?&]v=)|youtu\.be/)([a-zA-Z0-9_-]{11})} # rubocop:disable Layout/LineLength

    match = url.match(regex)

    return unless match && match[1]

    "https://www.youtube.com/embed/#{match[1]}"
  end
end
