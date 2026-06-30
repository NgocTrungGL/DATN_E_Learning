module Api
  module V1
    class RecommendationsController < ApplicationController
      before_action :authenticate_user!

      def index
        limit = params[:limit].to_i.clamp(1, 50)
        results = Recommendations::Engine.new(current_user).call(limit: limit)

        render json: {
          data: results.map { |r| recommendation_json(r) }
        }
      end

      def ai_embedding
        limit = params[:limit].to_i.clamp(1, 50)
        results = Recommendations::AiEmbeddingFilter.new(current_user).call(limit: limit)

        render json: {
          meta: {
            algorithm: "ai_embedding",
            user_id: current_user.id,
            limit: limit,
            result_count: results.size
          },
          data: results.map { |r| recommendation_json(r) }
        }
      end

      private

      def recommendation_json(result)
        {
          course_id: result.course_id,
          title: result.course.title,
          description: result.course.description&.truncate(120),
          thumbnail_url: result.course.thumbnail_url,
          price: result.course.price,
          category: result.course.category&.name,
          instructor: result.course.creator&.name,
          score: result.score,
          reason_type: result.reason_type
        }
      end
    end
  end
end
