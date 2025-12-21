Rails.application.routes.draw do
  root "courses#index"
  devise_for :users

  # --- THANH TOÁN ---
  post 'create-checkout-session', to: 'checkouts#create'
  post 'webhooks', to: 'webhooks#create'

  # --- USER (PROFILE & SETTINGS) ---
  resource :profile, only: [:edit, :update]
  get "password/edit", to: "passwords#edit"
  patch "password", to: "passwords#update"
  resources :email_confirmations, only: [:edit]
  resource :instructor_registration, only: [:new, :create, :show]
  resources :my_courses, only: [:index]

  # --- HỌC VIÊN (PUBLIC) ---
  resources :categories, only: [:index, :show]

  # Gom nhóm resources :courses lại cho gọn
  resources :courses, only: [:index, :show] do
    resources :reviews, only: [:create, :destroy]
    resources :enrollments, only: [:create]
  end

  resources :lessons, only: [:show] do
    resources :comments, only: [:create, :destroy]
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
    resources :revenues, only: [:index]
    resources :enrollments, only: [:index, :destroy]

    # Quản lý giảng viên
    resources :instructor_profiles, path: "instructors", controller: "instructor_profiles" do
      member do
        patch :approve
        patch :reject
      end
    end

    resources :payouts, only: [:index] do
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

    # Route cũ instructor (nếu bạn muốn giữ để xem danh sách chung)
    resources :instructors, only: [:index, :show] do
      member do
        patch :approve
        patch :reject
      end
    end
  end

  # --- INSTRUCTOR NAMESPACE (GIẢNG VIÊN) ---
  namespace :instructor do
    root to: "dashboard#index"
    resources :revenues, only: [:index]
    resources :payouts, only: [:create]
    resources :quizzes

    resources :courses do
      get :students, on: :member
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
  end

  # --- B2B: ĐĂNG KÝ DOANH NGHIỆP ---
  namespace :b2b do
    get 'register', to: 'registrations#new', as: 'register'
    post 'register', to: 'registrations#create'
  end

  # --- B2B: BUSINESS PORTAL (QUẢN TRỊ DOANH NGHIỆP) ---
  namespace :business do
    root 'dashboard#index'

    resources :employees
    resources :licenses, only: [:index] do
      post :assign, on: :collection
    end
    resources :course_market, only: [:index]
  end
end
