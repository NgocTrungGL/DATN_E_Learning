namespace :cloudinary do
  desc "Re-upload blobs to Cloudinary with proper public_id tracking"
  task reupload_blobs: :environment do
    cloud_name = ENV["CLOUDINARY_CLOUD_NAME"]
    api_key = ENV["CLOUDINARY_API_KEY"]
    api_secret = ENV["CLOUDINARY_API_SECRET"]
    base_url = "https://api.cloudinary.com/v1_1/#{cloud_name}"

    puts "Processing #{ActiveStorage::Blob.count} blobs..."

    ActiveStorage::Blob.find_each do |blob|
      next if blob.metadata["cloudinary_public_id"].present?

      content_type = blob.content_type.to_s
      resource_type = case content_type.split("/").first
                      when "video", "audio" then "video"
                      when "image" then "image"
                      else "raw"
                      end

      filename = blob.filename.to_s
      ext = filename.split(".").last

      begin
        io = StringIO.new
        blob.download { |chunk| io.write(chunk) }
        io.rewind
        content = io.read
      rescue => e
        puts "SKIP blob #{blob.id} - cannot download: #{e.message}"
        next
      end

      timestamp = Time.now.to_i
      sig_src = "timestamp=#{timestamp}#{api_secret}"
      signature = Digest::SHA1.hexdigest(sig_src)

      upload_url = "#{base_url}/#{resource_type}/upload?timestamp=#{timestamp}&api_key=#{api_key}&signature=#{signature}"

      boundary = "FormBoundary#{SecureRandom.hex(16)}"
      body = "--#{boundary}\r\n"
      body += "Content-Disposition: form-data; name=\"file\"; filename=\"#{filename}\"\r\n"
      body += "Content-Type: application/octet-stream\r\n\r\n"
      body += content
      body += "\r\n--#{boundary}--\r\n"

      uri = URI(upload_url)
      req = Net::HTTP::Post.new(uri)
      req["Content-Type"] = "multipart/form-data; boundary=#{boundary}"
      req.body = body

      resp = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(req)
      end

      if resp.code == "200"
        data = JSON.parse(resp.body)
        new_meta = (blob.metadata || {}).merge(
          "cloudinary_public_id" => data["public_id"],
          "cloudinary_version" => data["version"],
          "cloudinary_format" => data["format"]
        )
        blob.update!(metadata: new_meta)
        puts "OK blob #{blob.id}: #{data["public_id"]}"
      else
        puts "FAIL blob #{blob.id}: #{resp.code}"
      end

      sleep 0.5
    end

    puts "Done!"
  end
end
