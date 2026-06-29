namespace :learning do
  desc "Create behavior-based demo data for study plan personalization"
  task demo_behavior_personalization: :environment do
    result = Learning::BehaviorDemoDataBuilder.new(
      email: ENV["EMAIL"],
      course_id: ENV["COURSE_ID"]
    ).call

    puts "Demo learner: #{result.user.name} (##{result.user.id}, #{result.user.email})"
    puts "Course: #{result.course.title} (##{result.course.id})"
    puts "Study plan: ##{result.study_plan.id}"
    puts "Risk: #{result.risk.label} (score #{result.risk.score})"
    puts "Reasons:"
    result.risk.reasons.each { |reason| puts "- #{reason}" }
    puts "Focus recommendations: #{result.focus_items.size}"
    result.focus_items.each { |item| puts "- #{item.action_label}: #{item.lesson.title}" }
    puts "Plan suggestions: #{result.plan_suggestions.size}"
  end
end
