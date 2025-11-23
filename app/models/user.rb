class User < ApplicationRecord
  enum role: {
    admin: "admin",
    instructor: "instructor",
    student: "student"
  }
  has_one :profile, dependent: :destroy
  has_secure_password

  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  VALID_PASSWORD_REGEX = /\A
    (?=.*[a-z])
    (?=.*[A-Z])
    (?=.*\d)
    (?=.*[^A-Za-z0-9])
    .{8,}
  \z/x

  validates :name, presence: true

  validates :email,
            presence: true,
            uniqueness: true,
            format: {with: VALID_EMAIL_REGEX}

  validates :password,
            presence: true,
            format: {with: VALID_PASSWORD_REGEX},
            if: ->{new_record? || !password.nil?}
  accepts_nested_attributes_for :profile
  after_create :build_default_profile
  has_many :enrollments, dependent: :destroy
  has_many :enrolled_courses, through: :enrollments, source: :course

  has_many :quiz_attempts, dependent: :destroy
  has_many :progress_trackings, dependent: :destroy

  has_many :created_courses, class_name: Course.name, foreign_key: :creator_id,
dependent: :nullify
  has_many :created_quizzes, class_name: Quiz.name, foreign_key: :creator_id,
dependent: :nullify
  has_many :created_questions, class_name: Question.name,
foreign_key: :creator_id, dependent: :nullify

  def enrolled_in? course
    enrollments.exists?(course_id: course.id)
  end

  def can_access_course? course
    return true if admin?

    enrollments.active.exists?(course_id: course.id)
  end

  def lesson_completed? lesson
    progress_trackings.completed.exists?(lesson:)
  end

  def quiz_completed? quiz
    progress_trackings.completed.exists?(quiz:)
  end

  def course_progress_percentage course
    total_items = course.lessons.count + course.quizzes.count
    return 0 if total_items.zero?

    completed_items = progress_trackings.where(course:,
                                               status: :completed).count
    (completed_items.to_f / total_items * 100).round
  end
  private

  def build_default_profile
    create_profile
  end
end
