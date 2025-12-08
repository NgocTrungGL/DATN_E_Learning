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

  # --- INSTRUCTOR ---
  def instructor_rules user
    basic_instructor_access
    category_rules
    course_rules user
    module_and_lesson_rules user
    quiz_rules user
    enrollment_rules user
  end

  def basic_instructor_access
    can :read, :all
    can :access, :instructor_dashboard
  end

  def category_rules
    can :read, Category
    cannot [:create, :update, :destroy], Category
  end

  def course_rules user
    can :create, Course
    can [:update, :destroy], Course, created_by: user.id
  end

  def module_and_lesson_rules user
    can :manage, CourseModule,
        course: {created_by: user.id}

    can :manage, Lesson,
        course_module: {course: {created_by: user.id}}
  end

  def quiz_rules user
    can :manage, Quiz, created_by: user.id
    can :create, Question
    can [:read, :update, :destroy], Question,
        created_by: user.id

    can :manage, QuizQuestion,
        quiz: {created_by: user.id}
  end

  def enrollment_rules user
    can :read, Enrollment,
        course: {created_by: user.id}

    cannot [:approve, :reject], Enrollment
  end

  # --- STUDENT ---
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
