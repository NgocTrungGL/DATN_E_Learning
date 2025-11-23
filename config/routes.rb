Rails.application.routes.draw do
  devise_for :users
  # === THÊM CÁC DÒNG NÀY (CHO USER) ===

  # Tạo routes: /profile (GET), /profile (PATCH/PUT), /profile/edit (GET)
  # trỏ đến ProfilesController
  resource :profile, only: [:edit, :update]

  # Tạo routes: /password/edit (GET), /password (PATCH/PUT)
  # trỏ đến PasswordsController
  get "password/edit", to: "passwords#edit"
  patch "password", to: "passwords#update"

  # === KẾT THÚC ===
  root "courses#index"
  get '/login', to: 'sessions#new'
  post '/login', to: 'sessions#create'
  delete '/logout', to: 'sessions#destroy'
  get '/signup', to: 'registrations#new'
  post '/signup', to: 'registrations#create'
  resources :email_confirmations, only: [:edit]
  resources :courses, only: [:index, :show]
  resources :categories, only: [:index, :show]
  resources :lessons, only: [:show]

  resources :courses, only: [:index, :show] do
  # Nest enrollment vào course
  resources :enrollments, only: [:create]
  end
  #    POST /quizzes/:quiz_id/quiz_attempts
  resources :quizzes, only: [] do
    resources :quiz_attempts, only: [:create], shallow: false
  end
  #    GET /quiz_attempts/:id
  #    POST /quiz_attempts/:quiz_attempt_id/quiz_answers
  resources :quiz_attempts, only: [:show] do
    resources :quiz_answers, only: [:create], shallow: false
  end
  # ==================================================
  # ADMIN Routes
  # ==================================================
  namespace :admin do
    # root to: "dashboard#index"
    # Quản lý Danh mục
    resources :categories
    # Quản lý Ngân hàng câu hỏi
    resources :questions
    # Quản lý Khóa học, Chương, Bài học
    resources :courses do
      resources :course_modules, shallow: true do
        resources :lessons, shallow: true
      end
    end

    # (POST /admin/quizzes/:quiz_id/quiz_questions)
    resources :quizzes do
      resources :quiz_questions, only: [:create], shallow: false
    end

    # (DELETE /admin/quiz_questions/:id)
    resources :quiz_questions, only: [:destroy]
    resources :enrollments, only: [:index] do
      member do
        patch :approve # Tạo route: /admin/enrollments/:id/approve
        patch :reject
      end
    end
    resources :enrollments, only: [:index] do
      member do
        patch :approve # Route để duyệt: /admin/enrollments/:id/approve
        patch :reject  # Route để từ chối: /admin/enrollments/:id/reject
      end
    end
  end

end
