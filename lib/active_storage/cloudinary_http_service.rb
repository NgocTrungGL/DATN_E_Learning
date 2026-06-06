# Custom ActiveStorage Cloudinary Service su dung HTTP thay vi gem
# Gianh cho Ruby/Rails 7 voi Faraday 2.x
module ActiveStorage
  class CloudinaryHttpService < Service
    CLOUD_NAME = ENV["CLOUDINARY_CLOUD_NAME"]
    API_KEY = ENV["CLOUDINARY_API_KEY"]
    API_SECRET = ENV["CLOUDINARY_API_SECRET"]
    BASE_URL = "https://api.cloudinary.com/v1_1/#{CLOUD_NAME}"

    def upload(key, io, filename: nil, checksum: nil, **options)
      io.rewind if io.respond_to?(:rewind)
      content = io.read
      io.rewind if io.respond_to?(:rewind)

      resource_type = resource_type_for(io, key)
      filename ||= key.split("/").last

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

      unless response.code == "200"
        raise ActiveStorage::IntegrityError, "Cloudinary upload failed: #{response.code} - #{response.body}"
      end

      # Luu public_id, version, format vao blob metadata
      data = JSON.parse(response.body)
      public_id = data["public_id"]
      if public_id.present? && key.present?
        blob = ActiveStorage::Blob.find_by(key: key)
        if blob
          new_meta = (blob.metadata || {}).merge(
            "cloudinary_public_id" => public_id,
            "cloudinary_version" => data["version"],
            "cloudinary_format" => data["format"],
            "cloudinary_duration" => data["duration"]
          )
          blob.update!(metadata: new_meta)
        end
      end
    rescue => e
      raise ActiveStorage::IntegrityError, e.message
    end

    def url(key, filename: nil, content_type: nil, **options)
      blob = ActiveStorage::Blob.find_by(key: key)

      # Lay tu metadata neu co, nguoc lai dung filename lam public_id
      public_id = if blob&.metadata&.[]("cloudinary_public_id").present?
                    blob.metadata["cloudinary_public_id"]
                  else
                    blob&.filename&.to_s&.sub(/\.[^.]+\z/, "") || key.split("/").last.sub(/\.[^.]+\z/, "")
                  end

      format = blob&.metadata&.[]("cloudinary_format") || blob&.filename&.to_s&.split(".")&.last

      resource_type = resource_type_for_key(key)
      cdn_url = "https://res.cloudinary.com/#{CLOUD_NAME}/#{resource_type}/upload/#{public_id}"

      if format.present?
        cdn_url += ".#{format}"
      elsif filename.present?
        cdn_url += File.extname(filename)
      end

      if filename.present?
        cdn_url += "?fl_attachment=#{CGI.escape(filename)}"
      end

      cdn_url
    end

    def delete(key)
      public_id = get_public_id(key)
      resource_type = resource_type_for_key(key)

      timestamp = Time.now.to_i
      signature = Digest::SHA1.hexdigest("public_id=#{public_id}&timestamp=#{timestamp}&#{API_SECRET}")

      delete_url = "#{BASE_URL}/#{resource_type}/destroy?timestamp=#{timestamp}&api_key=#{API_KEY}&signature=#{signature}"

      uri = URI(delete_url)
      req = Net::HTTP::Post.new(uri)
      req["Content-Type"] = "application/x-www-form-urlencoded"
      req.body = "public_id=#{CGI.escape(public_id)}"

      Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }
    end

    def exist?(key)
      public_id = get_public_id(key)
      return false if public_id.blank?

      resource_type = resource_type_for_key(key)

      timestamp = Time.now.to_i
      signature = Digest::SHA1.hexdigest("public_id=#{public_id}&timestamp=#{timestamp}&#{API_SECRET}")

      check_url = "#{BASE_URL}/#{resource_type}/details_by_asset_id?public_id=#{CGI.escape(public_id)}&timestamp=#{timestamp}&api_key=#{API_KEY}&signature=#{signature}"

      uri = URI(check_url)
      res = Net::HTTP.get_response(uri)
      res.code == "200"
    end

    def download(key)
      public_id = get_public_id(key)
      resource_type = resource_type_for_key(key)

      timestamp = Time.now.to_i
      signature = Digest::SHA1.hexdigest("timestamp=#{timestamp}#{API_SECRET}")

      download_url = "#{BASE_URL}/#{resource_type}/upload/v#{timestamp}/#{public_id}?timestamp=#{timestamp}&api_key=#{API_KEY}&signature=#{signature}"

      uri = URI(download_url)
      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(Net::HTTP::Get.new(uri))
      end

      io = StringIO.new
      io.write(response.body)
      io.rewind
      io
    rescue => e
      raise ActiveStorage::FileNotFoundError, "Cloudinary download failed: #{e.message}"
    end

    private

    def get_public_id(key)
      blob = ActiveStorage::Blob.find_by(key: key)
      return key if blob.blank?

      blob.metadata["cloudinary_public_id"] || blob.filename.to_s.sub(/\.[^.]+\z/, "")
    end

    def resource_type_for_key(key)
      blob = ActiveStorage::Blob.find_by(key: key)
      content_type = blob&.content_type

      if content_type
        case content_type.to_s.split("/").first
        when "video", "audio" then "video"
        when "image" then "image"
        else "raw"
        end
      else
        ext = File.extname(key).downcase
        case ext
        when ".mp4", ".avi", ".mov", ".mkv", ".webm", ".flv", ".wmv", ".mp3", ".wav", ".ogg" then "video"
        when ".jpg", ".jpeg", ".png", ".gif", ".webp", ".svg", ".bmp", ".ico" then "image"
        else "raw"
        end
      end
    end

    def resource_type_for(io, key)
      content_type = io.respond_to?(:content_type) ? io.content_type : nil
      content_type ||= Marcel::MimeType.for(io) if io.respond_to?(:rewind)
      content_type ||= guess_content_type_from_key(key)

      case content_type.to_s.split("/").first
      when "video", "audio" then "video"
      when "image" then "image"
      else "raw"
      end
    end

    def guess_content_type_from_key(key)
      ext = File.extname(key).downcase
      case ext
      when ".mp4", ".avi", ".mov", ".mkv", ".webm" then "video/mp4"
      when ".mp3", ".wav", ".ogg" then "audio/mpeg"
      when ".jpg", ".jpeg" then "image/jpeg"
      when ".png" then "image/png"
      when ".gif" then "image/gif"
      when ".pdf" then "application/pdf"
      else "application/octet-stream"
      end
    end

    def build_multipart_body(content, filename, boundary)
      body = "--#{boundary}\r\n"
      body += "Content-Disposition: form-data; name=\"file\"; filename=\"#{filename}\"\r\n"
      body += "Content-Type: application/octet-stream\r\n\r\n"
      body += content
      body += "\r\n--#{boundary}--\r\n"
      body
    end
  end
end
