class Ability
  include CanCan::Ability

  def initialize user
    user ||= User.new

    if user.admin?
      admin_rules
    elsif user.instructor?
      instructor_rules(user)
    elsif user.student?
      student_rules(user)
    else
      guest_rules
    end
  end

  private

  def admin_rules
    can :manage, :all
    can :access, :admin_dashboard
  end

  def instructor_rules user
    can :read, :all
    can :access, :instructor_dashboard

    can :manage, Course, creator_id: user.id
    can :manage, CourseModule, course: {creator_id: user.id}
    can :manage, Lesson, course_module: {course: {creator_id: user.id}}

    # Quiz & Question
    can :manage, Quiz, creator_id: user.id
    can :manage, Question, creator_id: user.id
    can :manage, QuizQuestion, quiz: {creator_id: user.id}

    can :read, User, enrollments: {course: {creator_id: user.id}}
    can :read, Enrollment, course: {creator_id: user.id}

    cannot :create, InstructorProfile
    cannot :read, InstructorProfile
  end

  def student_rules user
    can :read, Course
    can :read, Category

    can :read, Lesson do |lesson|
      user.can_access_course?(lesson.course)
    end

    can :create, InstructorProfile do
      !user.instructor_profile&.persisted?
    end

    can :read, InstructorProfile, user_id: user.id
  end

  def guest_rules
    can :read, Course
    can :read, Category
  end
end
