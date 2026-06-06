# Service lay duration tu YouTube video bang oEmbed API
class YoutubeDurationService
  YOUTUBE_OEMBED_URL = "https://www.youtube.com/oembed"
  TIMEOUT_SECONDS = 5

  # Lay duration (tinh bang giay) tu YouTube URL
  # Tra ve so giay hoac 0 neu that bai
  def self.fetch_seconds(youtube_url)
    return 0 if youtube_url.blank?

    video_id = extract_video_id(youtube_url)
    return 0 if video_id.nil?

    # Thu lay tu YouTube Data API (chi tiet hon)
    seconds = fetch_from_data_api(video_id)
    return seconds if seconds > 0

    # Fallback: lay tu oEmbed (khong co duration trong oEmbed, chi lay thumbnail)
    # Chi tra ve 0, caller co the hien thi "Unknown duration"
    0
  rescue StandardError => e
    Rails.logger.warn "[YoutubeDurationService] Failed to fetch duration: #{e.message}"
    0
  end

  # Lay tu YouTube Data API (can API key)
  def self.fetch_from_data_api(video_id)
    api_key = ENV["YOUTUBE_API_KEY"]
    return 0 if api_key.blank?

    url = "https://www.googleapis.com/youtube/v3/videos"
    uri = URI("#{url}?id=#{video_id}&key=#{api_key}&part=contentDetails")

    req = Net::HTTP::Get.new(uri)
    req["Accept"] = "application/json"

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true,
                               read_timeout: TIMEOUT_SECONDS, open_timeout: TIMEOUT_SECONDS) do |http|
      http.request(req)
    end

    return 0 unless response.code == "200"

    data = JSON.parse(response.body)
    content_details = data.dig("items", 0, "contentDetails", "duration")

    return 0 if content_details.blank?

    parse_iso8601_duration(content_details)
  rescue StandardError => e
    Rails.logger.warn "[YoutubeDurationService] Data API failed: #{e.message}"
    0
  end

  # Parse ISO 8601 duration string thanh so giay
  # VD: "PT4M30S" -> 270, "PT1H2M30S" -> 3750
  def self.parse_iso8601_duration(duration_str)
    match = duration_str.match(/PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?/)
    return 0 unless match

    hours = match[1].to_i
    minutes = match[2].to_i
    seconds = match[3].to_i

    hours * 3600 + minutes * 60 + seconds
  end

  # Trich xuat video ID tu nhieu dang YouTube URL
  # Ho tro: youtube.com/watch?v=, youtu.be/, youtube.com/embed/, youtube.com/v/
  def self.extract_video_id(url)
    return url if url.present? && url.size <= 11 && !url.include?("/")

    patterns = [
      /(?:youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/embed\/|youtube\.com\/v\/)((?:[a-zA-Z0-9_-]{11}))/,
      /youtube\.com\/shorts\/([a-zA-Z0-9_-]{11})/
    ]

    patterns.each do |pattern|
      match = url.match(pattern)
      return match[1] if match
    end

    nil
  end
end
