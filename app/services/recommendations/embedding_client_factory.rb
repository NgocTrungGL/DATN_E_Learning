module Recommendations
  class EmbeddingClientFactory
    def self.build
      provider = ENV.fetch("EMBEDDING_PROVIDER", "openai").to_s.downcase

      case provider
      when "gemini", "google"
        Gemini::EmbeddingClient.new
      when "openai"
        OpenAi::EmbeddingClient.new
      else
        raise "Unsupported EMBEDDING_PROVIDER: #{provider}"
      end
    end
  end
end
