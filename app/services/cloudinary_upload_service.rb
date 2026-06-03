# Service upload file len Cloudinary bang HTTP
# Boi vi gem cloudinary gap van de voi Faraday 2.x multipart
# Su dung Digest::SHA1.hexdigest(secret) nhu Cloudinary API yeu cau
class CloudinaryUploadService
  CLOUD_NAME = ENV["CLOUDINARY_CLOUD_NAME"]
  API_KEY = ENV["CLOUDINARY_API_KEY"]
  API_SECRET = ENV["CLOUDINARY_API_SECRET"]
  BASE_URL = "https://api.cloudinary.com/v1_1/#{CLOUD_NAME}"

  def self.upload(io:, filename:, resource_type: "auto")
    io.rewind if io.respond_to?(:rewind)
    content = io.read
    io.rewind if io.respond_to?(:rewind)

    timestamp = Time.now.to_i
    signature = Digest::SHA1.hexdigest("timestamp=#{timestamp}#{API_SECRET}")

    upload_url = "#{BASE_URL}/#{resource_type}/upload?timestamp=#{timestamp}&api_key=#{API_KEY}&signature=#{signature}"

    boundary = "FormBoundary#{SecureRandom.hex(16)}"
    body = build_multipart_body(content, filename, boundary)

    uri = URI(upload_url)
    req = Net::HTTP::Post.new(uri)
    req["Content-Type"] = "multipart/form-data; boundary=#{boundary}"
    req.body = body

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(req)
    end

    handle_response(response)
  end

  def self.build_multipart_body(content, filename, boundary)
    body = "--#{boundary}\r\n"
    body += "Content-Disposition: form-data; name=\"file\"; filename=\"#{filename}\"\r\n"
    body += "Content-Type: application/octet-stream\r\n\r\n"
    body += content
    body += "\r\n--#{boundary}--\r\n"
    body
  end

  def self.handle_response(response)
    case response.code
    when "200"
      JSON.parse(response.body).with_indifferent_access
    when "400", "401", "403", "404", "500"
      error = JSON.parse(response.body)
      raise "Cloudinary upload failed: #{error.dig('error', 'message') || response.body}"
    else
      raise "Cloudinary upload failed: #{response.code} - #{response.body}"
    end
  end
end
