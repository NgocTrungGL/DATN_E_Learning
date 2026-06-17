# frozen_string_literal: true
# db/seeds/04_quizzes.rb

module SeedQuizzes
  QUIZ_TEMPLATES = {
    default: {
      questions: [
        {
          text: "Which of the following best describes the primary advantage of using an abstraction layer in software architecture?",
          type: 'single', difficulty: 'medium',
          options: [
            { text: "It eliminates all runtime errors automatically", correct: false },
            { text: "It decouples implementation details from the interface, allowing either side to change independently", correct: true },
            { text: "It always improves performance by reducing function call overhead", correct: false },
            { text: "It makes code shorter by combining multiple modules into one", correct: false },
          ]
        },
        {
          text: "In a distributed system, what does 'eventual consistency' guarantee?",
          type: 'single', difficulty: 'hard',
          options: [
            { text: "All nodes return identical data at every point in time", correct: false },
            { text: "Writes are acknowledged only after all replicas confirm them", correct: false },
            { text: "If no new updates are made, all replicas will eventually converge to the same value", correct: true },
            { text: "Data is never lost, even during a network partition", correct: false },
          ]
        },
        {
          text: "What is the time complexity of searching for an element in a balanced binary search tree?",
          type: 'single', difficulty: 'easy',
          options: [
            { text: "O(n)", correct: false },
            { text: "O(log n)", correct: true },
            { text: "O(n log n)", correct: false },
            { text: "O(1)", correct: false },
          ]
        },
        {
          text: "Which HTTP status codes indicate a client-side error? (Select all that apply)",
          type: 'multiple', difficulty: 'easy',
          options: [
            { text: "400 Bad Request", correct: true },
            { text: "401 Unauthorized", correct: true },
            { text: "500 Internal Server Error", correct: false },
            { text: "404 Not Found", correct: true },
            { text: "503 Service Unavailable", correct: false },
          ]
        },
        {
          text: "When would you choose a NoSQL database over a relational database?",
          type: 'single', difficulty: 'medium',
          options: [
            { text: "When you need ACID transactions across multiple entities", correct: false },
            { text: "When data has a rigid schema with complex relationships and joins", correct: false },
            { text: "When you need horizontal scaling with flexible, document-oriented or key-value data", correct: true },
            { text: "When storage cost is the primary concern", correct: false },
          ]
        },
        {
          text: "What does the SOLID principle 'Dependency Inversion' state?",
          type: 'single', difficulty: 'medium',
          options: [
            { text: "High-level modules should not depend on low-level modules; both should depend on abstractions", correct: true },
            { text: "Each class should have only one reason to change", correct: false },
            { text: "Objects should be open for extension but closed for modification", correct: false },
            { text: "Derived classes should be substitutable for their base classes", correct: false },
          ]
        },
        {
          text: "In the context of API design, what is the purpose of idempotency?",
          type: 'single', difficulty: 'medium',
          options: [
            { text: "Ensuring requests complete as fast as possible", correct: false },
            { text: "Guaranteeing that making the same request multiple times produces the same result as making it once", correct: true },
            { text: "Encrypting request payloads automatically", correct: false },
            { text: "Rate-limiting clients to prevent abuse", correct: false },
          ]
        },
        {
          text: "Which caching strategy writes to cache and storage simultaneously on every write?",
          type: 'single', difficulty: 'hard',
          options: [
            { text: "Cache-aside (Lazy Loading)", correct: false },
            { text: "Write-through", correct: true },
            { text: "Write-behind (Write-back)", correct: false },
            { text: "Read-through", correct: false },
          ]
        },
        {
          text: "What problem does database connection pooling solve?",
          type: 'single', difficulty: 'easy',
          options: [
            { text: "It compresses query results to reduce bandwidth", correct: false },
            { text: "It reuses a set of established connections to avoid the overhead of creating and tearing down connections on every request", correct: true },
            { text: "It automatically scales the database vertically under load", correct: false },
            { text: "It prevents SQL injection by sanitising input", correct: false },
          ]
        },
        {
          text: "In OAuth 2.0, what is the purpose of the 'refresh token'?",
          type: 'single', difficulty: 'medium',
          options: [
            { text: "To re-authenticate the user with their password", correct: false },
            { text: "To obtain a new access token when the current one expires, without requiring the user to log in again", correct: true },
            { text: "To invalidate all active sessions for a user", correct: false },
            { text: "To verify the identity of the client application", correct: false },
          ]
        },
      ]
    }
  }.freeze

  DOMAIN_QUESTIONS = {
    'Machine Learning' => [
      {
        text: "What is the bias-variance tradeoff in machine learning?",
        type: 'single', difficulty: 'medium',
        options: [
          { text: "The balance between training accuracy and inference speed", correct: false },
          { text: "The tradeoff between a model's ability to fit training data (low bias) and generalise to new data (low variance)", correct: true },
          { text: "The relationship between dataset size and model parameters", correct: false },
          { text: "The balance between precision and recall in classification", correct: false },
        ]
      },
      {
        text: "Which regularisation technique randomly drops neurons during training?",
        type: 'single', difficulty: 'easy',
        options: [
          { text: "L1 regularisation", correct: false },
          { text: "L2 regularisation", correct: false },
          { text: "Dropout", correct: true },
          { text: "Batch normalisation", correct: false },
        ]
      },
      {
        text: "What does cross-validation help prevent?",
        type: 'single', difficulty: 'easy',
        options: [
          { text: "Gradient vanishing during training", correct: false },
          { text: "Overfitting to the training set by estimating generalisation performance more reliably", correct: true },
          { text: "Data leakage from external sources", correct: false },
          { text: "Slow convergence in gradient descent", correct: false },
        ]
      },
      {
        text: "In gradient boosting, each subsequent learner is trained on:",
        type: 'single', difficulty: 'hard',
        options: [
          { text: "The original dataset, independently of other learners", correct: false },
          { text: "A random bootstrap sample of the training data", correct: false },
          { text: "The residual errors of the previous ensemble", correct: true },
          { text: "Only the samples misclassified by the previous learner", correct: false },
        ]
      },
    ],
    'Ruby on Rails' => [
      {
        text: "What is the purpose of `has_many :through` in Rails ActiveRecord?",
        type: 'single', difficulty: 'medium',
        options: [
          { text: "To eager-load associations and reduce N+1 queries", correct: false },
          { text: "To set up a many-to-many relationship via a join model, allowing extra attributes on the join", correct: true },
          { text: "To automatically cache frequently accessed associations", correct: false },
          { text: "To create polymorphic associations between models", correct: false },
        ]
      },
      {
        text: "Which Rails method in a controller prevents mass assignment vulnerabilities?",
        type: 'single', difficulty: 'easy',
        options: [
          { text: "before_action", correct: false },
          { text: "params.permit", correct: true },
          { text: "validates :attribute", correct: false },
          { text: "protect_from_forgery", correct: false },
        ]
      },
      {
        text: "In Rails, what is the difference between `render` and `redirect_to`?",
        type: 'single', difficulty: 'medium',
        options: [
          { text: "render makes an additional HTTP request; redirect_to does not", correct: false },
          { text: "redirect_to issues an HTTP redirect (new browser request); render returns a response directly without a new request", correct: true },
          { text: "They are functionally identical but render is preferred for performance", correct: false },
          { text: "render is for JSON responses; redirect_to is for HTML responses", correct: false },
        ]
      },
    ],
    'JavaScript' => [
      {
        text: "What is the output of `typeof null` in JavaScript?",
        type: 'single', difficulty: 'easy',
        options: [
          { text: '"null"', correct: false },
          { text: '"undefined"', correct: false },
          { text: '"object"', correct: true },
          { text: '"boolean"', correct: false },
        ]
      },
      {
        text: "What does the JavaScript event loop guarantee about callback execution?",
        type: 'single', difficulty: 'medium',
        options: [
          { text: "Callbacks always run in parallel on separate threads", correct: false },
          { text: "Callbacks run to completion without interruption, from the task queue when the call stack is empty", correct: true },
          { text: "Microtasks (Promises) always run after macrotasks (setTimeout)", correct: false },
          { text: "Callbacks are guaranteed to run within a fixed time window", correct: false },
        ]
      },
    ],
    'Finance' => [
      {
        text: "In a discounted cash flow (DCF) model, what does a higher discount rate imply about the present value?",
        type: 'single', difficulty: 'medium',
        options: [
          { text: "Present value increases as future cash flows are worth more today", correct: false },
          { text: "Present value decreases as future cash flows are worth less in today's terms", correct: true },
          { text: "The discount rate has no effect on present value", correct: false },
          { text: "Present value becomes negative when the discount rate exceeds the growth rate", correct: false },
        ]
      },
      {
        text: "What does a company's working capital represent?",
        type: 'single', difficulty: 'easy',
        options: [
          { text: "Total assets minus total liabilities", correct: false },
          { text: "Current assets minus current liabilities", correct: true },
          { text: "Cash and cash equivalents only", correct: false },
          { text: "Long-term debt minus equity", correct: false },
        ]
      },
    ],
  }.freeze

  def self.run!
    now        = SeedHelpers::NOW
    courses    = Course.published.order(:id).to_a
    instructors = User.where(role: 'instructor').to_a

    quizzes_batch  = []
    questions_batch = []
    options_batch   = []
    qq_batch        = []  # quiz_questions

    courses.each_with_index do |course, ci|
      quiz_count = rand(2..6)
      quiz_count.times do |qi|
        quizzes_batch << {
          course_id:       course.id,
          lesson_id:       nil,
          title:           "Module #{qi + 1} Assessment",
          description:     "Test your understanding of the key concepts covered in this section.",
          total_questions: rand(8..15),
          time_limit:      [15, 20, 25, 30, 45].sample,
          created_by:      course.created_by,
          pass_score:      [60, 65, 70, 75, 80].sample,
          random_mode:     true,
          easy_count:      rand(2..4),
          medium_count:    rand(3..6),
          hard_count:      rand(1..3),
          scoring_type:    0,
          created_at:      course.created_at,
          updated_at:      course.updated_at,
        }
      end
    end

    Quiz.insert_all!(quizzes_batch)
    puts "  ✓ #{quizzes_batch.length} quizzes"

    all_quizzes = Quiz.all.order(:id).to_a
    q_order = 0

    all_quizzes.each_with_index do |quiz, qi|
      question_pool = QUIZ_TEMPLATES[:default][:questions].shuffle.first(quiz.total_questions || 10)

      question_pool.each_with_index do |q_data, qpos|
        difficulty = q_data[:difficulty]

        questions_batch << {
          course_id:     quiz.course_id,
          lesson_id:     nil,
          question_text: q_data[:text],
          question_type: q_data[:type],
          difficulty:    difficulty,
          created_by:    quiz.created_by,
          created_at:    quiz.created_at,
          updated_at:    quiz.updated_at,
        }
        q_order += 1
      end
    end

    Question.insert_all!(questions_batch)
    puts "  ✓ #{questions_batch.length} questions"

    all_questions = Question.all.order(:id).to_a
    q_ptr = 0

    all_quizzes.each_with_index do |quiz, qi|
      pool_size = [quiz.total_questions || 10, QUIZ_TEMPLATES[:default][:questions].length].min
      question_pool = QUIZ_TEMPLATES[:default][:questions].first(pool_size)

      pool_size.times do |qpos|
        q_data    = question_pool[qpos]
        question  = all_questions[q_ptr]
        break unless question

        qq_batch << {
          quiz_id:     quiz.id,
          question_id: question.id,
          order_index: qpos + 1,
          created_at:  quiz.created_at,
          updated_at:  quiz.updated_at,
        }

        q_data[:options].each_with_index do |opt, oi|
          options_batch << {
            question_id:  question.id,
            option_text:  opt[:text],
            is_correct:   opt[:correct],
            option_order: oi + 1,
            created_at:   quiz.created_at,
            updated_at:   quiz.updated_at,
          }
        end

        q_ptr += 1
      end
    end

    # Batch insert quiz_questions (need deduplication)
    unique_qq = qq_batch.uniq { |r| [r[:quiz_id], r[:question_id]] }
    QuizQuestion.insert_all(unique_qq)
    QuestionOption.insert_all!(options_batch)
    puts "  ✓ #{options_batch.length} question options linked"
  end
end
