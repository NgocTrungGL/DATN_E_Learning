namespace :recommendations do
  desc "Embed published courses with OpenAI and cache vectors in course_embeddings"
  task embed_courses: :environment do
    limit = ENV["LIMIT"].presence&.to_i
    force = ENV["FORCE"] == "true"
    sleep_seconds = ENV.fetch("SLEEP", 0).to_f

    puts "Embedding published courses..."
    puts "Provider: #{ENV.fetch('EMBEDDING_PROVIDER', 'openai')}"
    stats = Recommendations::CourseEmbeddingBackfill.new.call(limit: limit, force: force, sleep_seconds: sleep_seconds)
    puts "Embedded: #{stats[:embedded]}"
    puts "Skipped: #{stats[:skipped]}"
    puts "Failed: #{stats[:failed]}"
    puts "Course embeddings: #{CourseEmbedding.count}/#{Course.published.count}"
  end

  desc "Compare existing hybrid recommender with OpenAI embedding recommender using offline holdout"
  task evaluate: :environment do
    k = ENV.fetch("K", 5).to_i
    user_limit = ENV.fetch("USER_LIMIT", 200).to_i
    result = Recommendations::OfflineEvaluator.new(k: k, user_limit: user_limit).call

    puts "Evaluated users: #{result[:evaluated_users]}"
    puts "K: #{result[:k]}"
    puts "Embedded courses: #{result[:embedded_courses]}/#{result[:published_courses]}"
    puts
    puts "Hybrid RCM"
    print_metrics(result[:hybrid])
    puts
    puts "AI Embedding"
    print_metrics(result[:ai_embedding])
    puts
    puts "Overlap@#{k}: #{format('%.4f', result[:overlap])}"

    path = Rails.root.join("tmp", "recommendation_eval_results.csv")
    export_eval_csv(result[:rows], path)
    puts
    puts "CSV: #{path}"
  end

  def print_metrics(metrics)
    puts "Exact HitRate: #{format('%.4f', metrics[:exact_hit_rate])}"
    puts "Exact Precision: #{format('%.4f', metrics[:exact_precision])}"
    puts "Exact Recall: #{format('%.4f', metrics[:exact_recall])}"
    puts "Exact NDCG: #{format('%.4f', metrics[:exact_ndcg])}"
    puts "Soft HitRate: #{format('%.4f', metrics[:soft_hit_rate])}"
    puts "Soft Precision: #{format('%.4f', metrics[:soft_precision])}"
    puts "Soft Recall: #{format('%.4f', metrics[:soft_recall])}"
    puts "Soft NDCG: #{format('%.4f', metrics[:soft_ndcg])}"
    puts "Avg Semantic: #{format('%.4f', metrics[:avg_semantic])}"
  end

  def export_eval_csv(rows, path)
    require "csv"

    CSV.open(path, "w") do |csv|
      csv << %w[user_id user_name algorithm rank course_id course_title score reason_type exact_relevant category_relevant semantic_relevant semantic_score soft_relevant]

      rows.each do |row|
        write_result_rows(csv, row, "hybrid_rcm", row[:hybrid_results], row[:hybrid_relevance])
        write_result_rows(csv, row, "ai_embedding", row[:ai_results], row[:ai_relevance])
      end
    end
  end

  def write_result_rows(csv, row, algorithm, results, relevance)
    results.each_with_index do |result, index|
      details = relevance.fetch(result.course_id, {})
      csv << [
        row[:user].id,
        row[:user].name,
        algorithm,
        index + 1,
        result.course_id,
        result.course.title,
        result.score,
        result.reason_type,
        details[:exact],
        details[:category],
        details[:semantic],
        details[:semantic_score],
        details[:soft]
      ]
    end
  end
end
