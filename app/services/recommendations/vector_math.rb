module Recommendations
  module VectorMath
    module_function

    def cosine_similarity(vector_a, vector_b)
      return 0.0 if vector_a.blank? || vector_b.blank? || vector_a.length != vector_b.length

      dot = 0.0
      norm_a = 0.0
      norm_b = 0.0

      vector_a.each_with_index do |value_a, index|
        a = value_a.to_f
        b = vector_b[index].to_f
        dot += a * b
        norm_a += a * a
        norm_b += b * b
      end

      return 0.0 if norm_a.zero? || norm_b.zero?

      dot / (Math.sqrt(norm_a) * Math.sqrt(norm_b))
    end

    def weighted_average(weighted_vectors)
      total_weight = weighted_vectors.sum { |item| item[:weight].to_f }
      return [] if total_weight.zero?

      size = weighted_vectors.first[:vector].length
      sums = Array.new(size, 0.0)

      weighted_vectors.each do |item|
        weight = item[:weight].to_f
        item[:vector].each_with_index { |value, index| sums[index] += value.to_f * weight }
      end

      sums.map { |value| value / total_weight }
    end
  end
end
