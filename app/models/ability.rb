class Ability
  include CanCan::Ability

  def initialize user
    @user = user || User.new

    if @user.admin?
      admin_rules
    elsif @user.instructor?
      instructor_rules
    elsif @user.student?
      student_rules
    else
      guest_rules
    end
  end

  private

  #############################################################
  # Admin
  #############################################################
  def admin_rules
    can :manage, :all
    can :access, :admin_dashboard
  end

  #############################################################
  # Instructor
  #############################################################
  def instructor_rules
    instructor_basic_access
    instructor_category_rules
    instructor_course_rules
    instructor_module_lesson_rules
    instructor_quiz_rules
    instructor_enrollment_rules

    instructor_content_access_rules
    # -------------------------------------------------

    can :read, Review
    can :create, Comment
    can :destroy, Comment, user_id: @user.id
  end

  def instructor_basic_access
    can :read, :all
    can :access, :instructor_dashboard
  end

  def instructor_category_rules
    can :read, Category
    cannot [:create, :update, :destroy], Category
  end

  def instructor_course_rules
    can :create, Course
    can [:update, :destroy], Course, created_by: @user.id
  end

  def instructor_module_lesson_rules
    can :manage, CourseModule, course: {created_by: @user.id}
    can :manage, Lesson, course_module: {course: {created_by: @user.id}}
  end

  def instructor_quiz_rules
    can :manage, Quiz, created_by: @user.id
    can :create, Question
    can [:read, :update, :destroy], Question, created_by: @user.id
    can :manage, QuizQuestion, quiz: {created_by: @user.id}
  end

  def instructor_enrollment_rules
    can :read, Enrollment, course: {created_by: @user.id}
    cannot [:approve, :reject], Enrollment
  end

  def instructor_content_access_rules
    can :access_content, Course, created_by: @user.id

    can :access_content, Course do |course|
      @user.enrollments.active.exists?(course_id: course.id)
    end
  end

  #############################################################
  # Student
  #############################################################
  def student_rules
    can :read, [Category]
    can :read, Course

    can :create, [Review, Comment]
    can :destroy, Review, user_id: @user.id
    can :destroy, Comment, user_id: @user.id

    can :access_content, Course do |course|
      @user.enrollments.active.exists?(course_id: course.id)
    end
    # ---------------------------------------

    can :create, InstructorProfile do
      !@user.instructor_profile&.persisted?
    end

    can :read, InstructorProfile, user_id: @user.id
  end

  #############################################################
  # Guest
  #############################################################
  def guest_rules
    can :read, [Course, Category]
  end
end
