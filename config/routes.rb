Rails.application.routes.draw do
  get "health", to: proc { [200, { "Content-Type" => "text/plain" }, ["OK"]] }
  get "sentry-test", to: proc {
    error = StandardError.new("Sentry production demo test error")
    Sentry.capture_exception(error)
    Sentry.get_current_client&.flush
    raise error
  } if ENV["ENABLE_SENTRY_TEST_ROUTE"] == "true"

  %w[400 401 403 404 406 422 429 500 503].each do |code|
    get code, to: "errors#show", code: code
  end
  get "error", to: "errors#show", code: "error"

  namespace :api do
    namespace :v1 do
      resources :recommendations, only: [:index] do
        get :ai_embedding, on: :collection
      end
      get "categories/:id/subcategories", to: "categories#subcategories"
    end
  end

  resources :notifications, only: [:index, :update] do
    collection do
      post :mark_all_as_read
    end
  end
  root "home#index"
  get "instructors/:id", to: "public_instructors#show", as: :public_instructor
  devise_for :users
  post 'create-checkout-session', to: 'checkouts#create'

  # --- THANH TOÁN ---
  post 'create-checkout-session', to: 'checkouts#create'
  post 'webhooks', to: 'webhooks#create'
  resource :cart, only: [:show] do
    post :apply_coupon, on: :member
    post :apply_coupon_api, on: :member
  end
  post 'checkout-cart', to: 'checkouts#create_from_cart', as: 'checkout_cart'

  # Route trang thành công
  get 'checkout-success', to: 'checkouts#success', as: 'checkout_success'
  resources :cart_items, only: [:create, :destroy] do
    member do
      post :move_to_wishlist
    end
  end
  # --- USER (PROFILE & SETTINGS) ---
  resource :profile, only: [:edit, :update]
  get "password/edit", to: "passwords#edit"
  patch "password", to: "passwords#update"
  resources :email_confirmations, only: [:edit]
  resource :instructor_registration, only: [:new, :create, :show]
  resources :my_courses, only: [:index]
  resources :my_notes, only: [:index]
  resources :wishlists, only: [:index]
  post 'wishlists/:course_id/move_to_cart', to: 'wishlists#move_to_cart', as: 'move_wishlist_to_cart'
  resources :certificates, only: [:index, :show], param: :code do
    member do
      get :print
    end
  end
  resources :subscriptions, only: [:index, :create, :destroy] do
    member do
      patch :resume
    end
  end

  # --- HỌC VIÊN (PUBLIC) ---
  resources :categories, only: [:index, :show]

  # Gom nhóm resources :courses lại cho gọn
  resources :courses, only: [:index, :show] do
    post :toggle_wishlist, to: "wishlists#toggle", as: "toggle_wishlist"
    resources :reviews, only: [:create, :destroy] do
      collection do
        get :more
      end
    end
    resources :enrollments, only: [:create]
    resources :discussion_messages, path: "chat", only: [:index, :create, :destroy] do
      collection do
        get :mentions
      end
      member do
        get  :thread
        post :replies, to: "discussion_message_replies#create"
        post :toggle_reaction, to: "discussion_message_reactions#create"
      end
    end
    resources :discussion_posts, path: "discussions", only: [:index, :show, :create, :update, :destroy] do
      member do
        patch :toggle_pin
        patch :toggle_lock
      end
      resources :discussion_replies, path: "replies", only: [:create, :update, :destroy]
    end
  end

  resources :lessons, only: [:show] do
    resources :comments, only: [:create, :destroy]
    resources :notes, only: [:create]
    post :complete, to: "progress_trackings#mark_lesson_complete"
    post :video_progress, to: "progress_trackings#video_progress"
    post :auto_complete, to: "progress_trackings#auto_complete"
    get :progress, to: "progress_trackings#get_progress"
  end
  resources :notes, only: [:update, :destroy]

  resources :quizzes, only: [] do
    resources :quiz_attempts, only: [:create], shallow: false
  end
  resources :quiz_attempts, only: [:show] do
    resources :quiz_answers, only: [:create], shallow: false
    member do
      patch :finish
      get :review
    end
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

    # 1. ADMIN TỰ TẠO/SỬA KHÓA HỌC CỦA MÌNH
    resources :courses do
      member do
        get :lessons
      end
      resources :course_modules, shallow: true do
        resources :lessons, shallow: true
      end
    end

    # 2. ADMIN DUYỆT KHÓA HỌC CỦA GIẢNG VIÊN (MỚI)
    resources :course_reviews, only: [:index] do
      member do
        patch :approve
        patch :reject
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
    resources :coupons
    resources :recommendation_evaluations, only: [:index]
    resources :personalization_reports, only: [:index] do
      collection do
        post :refresh_demo
      end
    end
  end

  # --- INSTRUCTOR NAMESPACE (GIẢNG VIÊN) ---
  namespace :instructor do
    root to: "dashboard#index"
    resources :activities, only: [:index]
    resources :revenues, only: [:index]
    resources :payouts, only: [:create]
    resources :quizzes
    resources :quiz_attempts, only: [:index]
    resources :student_analytics, only: [:index, :show]
    resources :course_performance, only: [:index, :show]
    resources :discussions, only: [:index]
    get "courses/:course_id/builder" => "course_builder#show", as: :course_builder
    patch "courses/:course_id/sort_modules" => "course_builder#sort_modules", as: :sort_modules
    patch "courses/:course_id/sort_lessons" => "course_builder#sort_lessons", as: :sort_lessons

    resources :courses do
      member do
        get  :students
        patch :sort_modules
        patch :sort_lessons
        patch :submit_for_review
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
    resources :coupons
  end

  # --- B2B: ĐĂNG KÝ DOANH NGHIỆP ---
  namespace :b2b do
    get 'register', to: 'registrations#new', as: 'register'
    post 'register', to: 'registrations#create'
  end

  # --- B2B: BUSINESS PORTAL (QUẢN TRỊ DOANH NGHIỆP) ---
  namespace :business do
    root 'dashboard#index'

    resources :employees do
      member do
        get :progress, controller: "employee_progress", action: "show"
        get :export, controller: "employee_progress"
      end
    end
    resources :licenses, only: [:index] do
      post :assign, on: :collection
      member do
        post :revoke
      end
    end
    resources :course_market, only: [:index]

    resources :bulk_imports, only: [:new, :create] do
      collection do
        get :template
      end
    end

    resources :purchases, only: [:new, :create]
    resources :invoices, only: [:index, :show]
    resources :employee_reports, only: [:index] do
      get :suggestions, on: :collection
    end
    resources :reports, only: [:index]
  end

  # --- STUDENT: PERSONAL DASHBOARD ---
  namespace :student do
    resource :dashboard, only: [:show], controller: "dashboard"
    resources :learning_goals, only: [:index, :create, :update, :destroy]
    resources :study_plans, only: [:index, :show, :new, :create, :edit, :update, :destroy] do
      member do
        post :pause
        post :resume
        post :regenerate
        post :refresh_focus
      end
    end
    resources :study_plan_items, only: [] do
      member do
        post :start
        post :complete
        post :skip
      end
    end
  end
end
