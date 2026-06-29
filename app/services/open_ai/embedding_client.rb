require "net/http"

module OpenAi
  class EmbeddingClient
    ENDPOINT = "https://api.openai.com/v1/embeddings"

    def initialize(api_key: ENV["OPENAI_API_KEY"], model: ENV.fetch("OPENAI_EMBEDDING_MODEL", "text-embedding-3-small"))
      @api_key = api_key
      @model = model
      @open_timeout = ENV.fetch("EMBEDDING_OPEN_TIMEOUT", 10).to_i
      @read_timeout = ENV.fetch("EMBEDDING_READ_TIMEOUT", 30).to_i
    end

    def embed(text)
      raise "Missing OPENAI_API_KEY" if @api_key.blank?

      uri = URI(ENDPOINT)
      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{@api_key}"
      request["Content-Type"] = "application/json"
      request.body = {
        model: @model,
        input: text.to_s
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
      raise body.dig("error", "message") || "OpenAI embeddings request failed" unless response.is_a?(Net::HTTPSuccess)

      body.dig("data", 0, "embedding") || raise("OpenAI response did not include an embedding")
    end
  end
end
