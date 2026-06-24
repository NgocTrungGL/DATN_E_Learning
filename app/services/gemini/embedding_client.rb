require "net/http"

module Gemini
  class EmbeddingClient
    API_BASE = "https://generativelanguage.googleapis.com/v1beta/models"

    def initialize(api_key: ENV["GEMINI_API_KEY"], model: ENV.fetch("GEMINI_EMBEDDING_MODEL", "gemini-embedding-001"))
      @api_key = api_key
      @model = model
      @open_timeout = ENV.fetch("EMBEDDING_OPEN_TIMEOUT", 10).to_i
      @read_timeout = ENV.fetch("EMBEDDING_READ_TIMEOUT", 30).to_i
    end

    def embed(text)
      raise "Missing GEMINI_API_KEY" if @api_key.blank?

      uri = URI("#{API_BASE}/#{@model}:embedContent?key=#{@api_key}")
      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request.body = {
        content: {
          parts: [{ text: text.to_s }]
        }
      }.to_json

      response = Net::HTTP.start(
        uri.hostname,
        uri.port,
        use_ssl: true,
        open_timeout: @open_timeout,
        read_timeout: @read_timeout
      ) do |http|
        http.request(request)
      end

      body = JSON.parse(response.body)
      raise body.dig("error", "message") || "Gemini embeddings request failed" unless response.is_a?(Net::HTTPSuccess)

      body.dig("embedding", "values") || raise("Gemini response did not include an embedding")
    end
  end
end
