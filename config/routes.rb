Rails.application.routes.draw do
  root "courses#index"

  resource :profile, only: [:edit, :update]

  # Password
  get  "password/edit", to: "passwords#edit"
  patch "password",     to: "passwords#update"

  # Sessions
  get    "/login",  to: "sessions#new"
  post   "/login",  to: "sessions#create"
  delete "/logout", to: "sessions#destroy"

  # Registration
  get  "/signup", to: "registrations#new"
  post "/signup", to: "registrations#create"

  # Email Confirmations
  resources :email_confirmations, only: [:edit]

  # ================================
  # Courses (User side)
  # ================================
  resources :courses, only: [:index, :show] do
    resources :enrollments, only: [:create]   # POST /courses/:course_id/enrollments
  end

  resources :my_courses, only: [:index]
  resources :categories, only: [:index, :show]
  resources :lessons,    only: [:show] do
    post :complete, to: 'progress_trackings#mark_lesson_complete'
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
    # ========= Categories =========
    resources :categories

    # ========= Courses + Modules + Lessons =========
    resources :courses do
      resources :course_modules, shallow: true do
        resources :lessons, shallow: true
      end

      member do
        get :lessons    # /admin/courses/:id/lessons
      end
    end

    # Sorting modules and lessons
    resources :course_modules, only: [] do
      collection { patch :sort }  # /admin/course_modules/sort
    end

    resources :lessons, only: [] do
      collection { patch :sort }  # /admin/lessons/sort
    end

    # ========= Quiz Bank =========
    resources :questions
    resources :quizzes do
      resources :quiz_questions, only: [:create]
    end
    resources :quiz_questions, only: [:destroy]

    # ========= Enrollments =========
    resources :enrollments, only: [:index] do
      member do
        patch :approve
        patch :reject
      end
    end

    # ========= Users =========
    resources :users, only: [:index, :show, :update, :destroy]
  end
end
