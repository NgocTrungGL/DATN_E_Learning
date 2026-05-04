class Ability
  include CanCan::Ability

  def initialize user
    @user = user || User.new

    if @user.admin?
      admin_rules
    elsif @user.instructor?
      instructor_rules
    elsif @user.company_admin?
      company_admin_rules
    elsif @user.employee?
      employee_rules
    elsif @user.student?
      student_rules
    else
      guest_rules
    end
  end

  private

  #############################################################
  # HELPER
  #############################################################
  def can_access_course_content
    can :access_content, Course do |course|
      # Check enrollment (Student)
      has_enrollment = @user.enrollments.active.exists?(course_id: course.id)

      # Check license (Employee/Company Admin)
      has_license = @user.licenses.exists?(course_id: course.id,
                                           status: :assigned)

      # Check creator (Instructor)
      is_creator = (course.created_by == @user.id)

      has_enrollment || has_license || is_creator
    end
  end

  def can_read_lesson_rule
    can :read, Lesson do |lesson|
      lesson.free_preview? || can?(:access_content, lesson.course)
    end
  end

  def common_interaction_rules
    can :read, [Category, Course, Review, Comment]
    can :create, [Review, Comment]
    can :destroy, Review, user_id: @user.id
    can :destroy, Comment, user_id: @user.id
    can :manage, Note, user_id: @user.id

    # Discussion permissions
    can :read, DiscussionPost
    can :create, DiscussionPost
    can [:update, :destroy], DiscussionPost, user_id: @user.id
    can :create, DiscussionReply
    can [:update, :destroy], DiscussionReply, user_id: @user.id

    # Chat permissions
    can :read, DiscussionMessage
    can :create, DiscussionMessage
    can :destroy, DiscussionMessage, user_id: @user.id
  end

  #############################################################
  # 1. Admin
  #############################################################
  def admin_rules
    can :manage, :all
    can :access, :admin_dashboard
  end

  #############################################################
  # 2. Instructor
  #############################################################
  def instructor_rules
    instructor_basic_access
    instructor_category_rules
    instructor_course_rules
    instructor_module_lesson_rules
    instructor_quiz_rules
    instructor_enrollment_rules

    can_access_course_content

    can_read_lesson_rule

    common_interaction_rules
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
    can [:update, :destroy, :submit_for_review], Course, created_by: @user.id
  end

  def instructor_module_lesson_rules
    can :manage, CourseModule, course: { created_by: @user.id }
    can :manage, Lesson, course_module: { course: { created_by: @user.id } }
  end

  def instructor_quiz_rules
    can :manage, Quiz, created_by: @user.id
    can :create, Question
    can [:read, :update, :destroy], Question, created_by: @user.id
    can :manage, QuizQuestion, quiz: { created_by: @user.id }
  end

  def instructor_enrollment_rules
    can :read, Enrollment, course: { created_by: @user.id }
    cannot [:approve, :reject], Enrollment
  end

  #############################################################
  # 3. Company Admin
  #############################################################
  def company_admin_rules
    common_interaction_rules

    can :access, :business_dashboard

    can :manage, Organization, user_id: @user.id

    if @user.organization
      can :read, License, organization_id: @user.organization.id
      can :update, License, organization_id: @user.organization.id
    end

    can_access_course_content

    can_read_lesson_rule
  end

  #############################################################
  # 4. Employee (Thay cho B2B)
  #############################################################
  def employee_rules
    common_interaction_rules
    can_access_course_content

    can_read_lesson_rule

    cannot :access,
           [:admin_dashboard, :instructor_dashboard, :business_dashboard]
  end

  #############################################################
  # 5. Student
  #############################################################
  def student_rules
    common_interaction_rules
    can_access_course_content

    can :create, InstructorProfile do
      !@user.instructor_profile&.persisted?
    end

    can :read, InstructorProfile, user_id: @user.id

    can_read_lesson_rule
  end

  #############################################################
  # 6. Guest
  #############################################################
  def guest_rules
    can :read, [Course, Category, Review, Comment]

    can :read, Lesson, free_preview: true
  end
end
