Rails.application.routes.draw do
  root "courses#index"

  # ================================
  # Devise (User Auth)
  # ================================
  devise_for :users

  # Profile
  resource :profile, only: [:edit, :update]

  # Email confirmation
  resources :email_confirmations, only: [:edit]

  # ================================
  # Courses (User side)
  # ================================
  resources :courses, only: [:index, :show] do
    resources :enrollments, only: [:create]
  end

  resources :my_courses, only: [:index]
  resources :categories, only: [:index, :show]
  resource :instructor_registration, only: [:new, :create, :show]
  resources :lessons, only: [:show] do
    post :complete, to: "progress_trackings#mark_lesson_complete"
  end

  # ================================
  # Quiz
  # ================================
  resources :quizzes, only: [] do
    resources :quiz_attempts, only: [:create]
  end

  resources :quiz_attempts, only: [:show] do
    resources :quiz_answers, only: [:create]
    patch :finish, on: :member
  end

  # ================================
  # Admin
  # ================================
  namespace :admin do
    # Categories
    resources :categories

    # Courses + Modules + Lessons
    resources :courses do
      resources :course_modules, shallow: true do
        resources :lessons, shallow: true
      end

      # /admin/courses/:id/lessons
      member do
        get :lessons
      end
    end

    # Sorting
    resources :course_modules, only: [] do
      collection { patch :sort }
    end

    resources :lessons, only: [] do
      collection { patch :sort }
    end

    # Quiz Bank
    resources :questions
    resources :quizzes do
      resources :quiz_questions, only: [:create]
    end
    resources :quiz_questions, only: [:destroy]

    # Enrollments
    resources :enrollments, only: [:index] do
      member do
        patch :approve
        patch :reject
      end
    end

    # Users
    resources :users, only: [:index, :show, :update, :destroy]
  end
  # ================================
  # Instructor
  # ================================
  namespace :instructor do
    root to: "dashboard#index"
    resources :courses
  end

  namespace :admin do

    resources :instructors, only: [:index, :show] do
      member do
        patch :approve
        patch :reject
      end
    end
  end
end
