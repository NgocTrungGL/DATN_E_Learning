# ==============================
# config/routes.rb
# ==============================
Rails.application.routes.draw do
  root "courses#index"
  devise_for :users

  # --- USER ---
  resource :profile, only: [:edit, :update]
  get "password/edit", to: "passwords#edit"
  patch "password", to: "passwords#update"
  resources :email_confirmations, only: [:edit]
  resource :instructor_registration, only: [:new, :create, :show]
  resources :my_courses, only: [:index]

  resources :categories, only: [:index, :show]
  resources :courses do
    resources :reviews, only: [:create, :destroy]
  end

  resources :lessons do
    resources :comments, only: [:create, :destroy]
  end
  resources :courses, only: [:index, :show] do
    resources :enrollments, only: [:create]
  end
  resources :lessons, only: [:show] do
    post :complete, to: "progress_trackings#mark_lesson_complete"
  end
  resources :quizzes, only: [] do
    resources :quiz_attempts, only: [:create], shallow: false
  end
  resources :quiz_attempts, only: [:show] do
    resources :quiz_answers, only: [:create], shallow: false
    patch :finish, on: :member
  end

  # --- ADMIN ---
  namespace :admin do
    get 'dashboard', to: 'dashboard#index'
    resources :users, only: [:index, :show, :update, :destroy]
    resources :reviews, only: [:index, :destroy]
    resources :comments, only: [:index, :destroy]
    # Quản lý giảng viên
    resources :instructor_profiles,
              path: "instructors",
              controller: "instructor_profiles" do
      member do
        patch :approve
        patch :reject
      end
    end

    resources :enrollments, only: [:index] do
      member do
        patch :approve
        patch :reject
      end
    end

    resources :categories
    resources :courses do
      member do
        get :lessons
      end
      resources :course_modules, shallow: true do
        resources :lessons, shallow: true
      end
    end

    resources :course_modules, only: [] do
      collection { patch :sort }
    end
    resources :lessons, only: [] do
      collection { patch :sort }
    end

    resources :questions
    resources :quizzes do
      resources :quiz_questions, only: [:create], shallow: false
    end
    resources :quiz_questions, only: [:destroy]

    resources :instructors, only: [:index, :show] do
      member do
        patch :approve
        patch :reject
      end
    end
  end

# ==================================================
  # 5. INSTRUCTOR NAMESPACE (GIẢNG VIÊN)
  # ==================================================
  namespace :instructor do
    root to: "dashboard#index"
    resources :quizzes
    # 1. Quản lý Khóa học & Nội dung lồng nhau
    resources :courses do
      get :students, on: :member

      resources :course_modules, shallow: true do
        # XÓA collection { patch :sort } Ở ĐÂY
        resources :lessons, shallow: true do
          # XÓA collection { patch :sort } Ở ĐÂY
        end
      end
    end

    # 2. Route Sắp xếp (Đưa ra ngoài để có helper ngắn gọn)
    # Helper: sort_instructor_course_modules_path
    resources :course_modules, only: [] do
      collection { patch :sort }
    end

    # Helper: sort_instructor_lessons_path
    resources :lessons, only: [] do
      collection { patch :sort }
    end

    # 3. Quản lý Quiz & Câu hỏi
    resources :questions
    resources :quizzes do
      resources :quiz_questions, only: [:create], shallow: false
    end
    resources :quiz_questions, only: [:destroy]
  end
end
