class Admin::RecommendationEvaluationsController < Admin::BaseController
  skip_load_and_authorize_resource

  def index
    @k = params.fetch(:k, Recommendations::OfflineEvaluator::DEFAULT_K).to_i.clamp(1, 20)
    @candidate_users = candidate_users
    @selected_user = selected_user
    @evaluation = @selected_user ? Recommendations::OfflineEvaluator.new(k: @k, user_limit: 1).evaluate_user(@selected_user) : nil
    @history_courses = history_courses
    @ground_truth_courses = Course.where(id: @evaluation&.dig(:ground_truth_ids)).index_by(&:id)
    @hybrid_result_rows = result_rows(:hybrid_results, :hybrid_relevance)
    @ai_result_rows = result_rows(:ai_results, :ai_relevance)
    @embedding_coverage = {
      embedded: CourseEmbedding.count,
      published: Course.published.count
    }
  end

  private

  def candidate_users
    User.where(role: "student")
        .joins(:enrollments)
        .group("users.id")
        .having("COUNT(enrollments.id) >= 5")
        .order("users.id")
        .limit(50)
  end

  def selected_user
    return @candidate_users.first if params[:user_id].blank?

    @candidate_users.detect { |user| user.id == params[:user_id].to_i } || @candidate_users.first
  end

  def history_courses
    ids = @evaluation&.dig(:profile_interactions)&.keys || []
    Course.where(id: ids).includes(:category).index_by(&:id)
  end

  def result_rows(results_key, relevance_key)
    results = @evaluation&.dig(results_key) || []
    relevance = @evaluation&.dig(relevance_key) || {}

    results.each_with_index.map do |result, index|
      {
        rank: index + 1,
        result: result,
        relevance: relevance.fetch(result.course_id, {})
      }
    end
  end
end
