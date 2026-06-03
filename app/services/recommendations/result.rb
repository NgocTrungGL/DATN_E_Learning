module Recommendations
  Result = Struct.new(:course_id, :course, :score, :reason_type, keyword_init: true)
end
