# frozen_string_literal: true
# db/seeds/03_courses_and_content.rb

module SeedCoursesAndContent
  # ── Course titles per subcategory ──────────────────────────
  TITLES = {
    'Machine Learning' => [
      'Machine Learning A-Z: Complete Python & Scikit-Learn Masterclass',
      'Applied Machine Learning: From Notebook to Production',
      'Feature Engineering and Selection for ML Practitioners',
      'ML System Design: Architecting Scalable AI Pipelines',
      'Bayesian Machine Learning and Probabilistic Programming',
      'Ensemble Methods Deep Dive: Boosting, Bagging, and Stacking',
      'ML Monitoring: Drift Detection and Model Health in Production',
      'Recommendation Systems: Collaborative Filtering to Neural Approaches',
    ],
    'Deep Learning' => [
      'Deep Learning with PyTorch: From Fundamentals to Production',
      'Neural Networks from Scratch: Mathematical Foundations and Implementation',
      'Advanced CNNs: Object Detection, Segmentation, and Beyond',
      'Transformer Architecture: Attention, BERT, and GPT Internals',
      'Generative AI: GANs, VAEs, and Diffusion Models Explained',
      'Deep Reinforcement Learning: Theory and Implementation in Python',
      'TensorFlow 2.x and Keras: Complete Professional Guide',
      'Training Large Language Models from Scratch',
    ],
    'Computer Vision' => [
      'Computer Vision Engineering with OpenCV and Deep Learning',
      'Real-Time Object Detection: YOLO v8 and Beyond',
      'Medical Image Analysis with Convolutional Neural Networks',
      'Video Understanding: Action Recognition and Visual Tracking',
      '3D Computer Vision: Point Clouds and Depth Estimation',
      'Document AI: OCR, Layout Understanding, and Information Extraction',
    ],
    'NLP' => [
      'Natural Language Processing with Hugging Face Transformers',
      'BERT Fine-Tuning for Classification, NER, and Q&A',
      'Text Processing at Scale: From Preprocessing to Deployment',
      'Building Conversational AI: Dialogue Systems and Chatbots',
      'Multilingual NLP: Cross-Lingual Transfer and Low-Resource Languages',
    ],
    'LLM' => [
      'LLM Engineering: Building Production AI Applications',
      'Fine-Tuning LLMs: LoRA, QLoRA, and PEFT Methods',
      'LangChain in Production: Patterns, Pipelines, and Best Practices',
      'LLM Evaluation and Quality Assurance Frameworks',
      'LLM Security: Prompt Injection, Data Leakage, and Defences',
      'Multimodal LLMs: GPT-4V, LLaVA, and Vision-Language Models',
    ],
    'Prompt Engineering' => [
      'Advanced Prompt Engineering: Systematic Techniques for Reliable Results',
      'Chain-of-Thought Prompting and Structured Reasoning',
      'Prompt Engineering for Code Generation and Software Development',
      'Enterprise Prompt Management: Version Control and Testing',
    ],
    'AI Agent' => [
      'Building Autonomous AI Agents: Architecture and Implementation Guide',
      'Multi-Agent Orchestration with LangGraph and AutoGen',
      'Tool Use and Function Calling in Agentic AI Systems',
      'AI Agents for Business Process Automation',
    ],
    'RAG Systems' => [
      'Retrieval-Augmented Generation: Complete End-to-End Guide',
      'Advanced RAG: Hybrid Search, Reranking, and Evaluation',
      'Production RAG Pipelines with LlamaIndex and pgvector',
      'Multimodal RAG: Integrating Text, Images, and Structured Data',
    ],
    'Ruby' => [
      'The Complete Ruby Programming Language Masterclass',
      'Ruby Metaprogramming: Writing Expressive, Flexible Code',
      'Concurrent and Parallel Programming in Ruby',
      'Ruby Design Patterns: Clean Code for Scalable Applications',
    ],
    'Ruby on Rails' => [
      'Ruby on Rails 7: Complete Full-Stack Web Development',
      'Rails API Backend: RESTful Services and GraphQL',
      'Advanced Rails Architecture: Scaling to Production Traffic',
      'Rails Testing Excellence: RSpec, FactoryBot, and System Tests',
      'Hotwire with Rails: Turbo Streams, Turbo Frames, and Stimulus',
      'Rails Security: OWASP Vulnerabilities and Hardening Strategies',
      'Background Jobs with Sidekiq: Patterns and Production Practices',
      'Building Multi-Tenant SaaS with Rails',
    ],
    'Python' => [
      'Python Mastery: From Beginner to Professional Software Engineer',
      'Advanced Python: Decorators, Metaclasses, and Descriptors',
      'Python Concurrency: Asyncio, Threading, and Multiprocessing',
      'FastAPI: Building Modern, High-Performance Python APIs',
      'Python Testing Masterclass: Pytest, Mocks, and TDD',
      'Python for DevOps: Automation, Scripting, and Infrastructure',
      'Python Performance: Profiling, Caching, and Optimisation',
      'Python Package Engineering: Building and Publishing Libraries',
    ],
    'JavaScript' => [
      'JavaScript: The Complete Modern Guide (ES2024)',
      'Functional JavaScript: Composition, Immutability, and Monads',
      'JavaScript Engine Internals: V8, Memory, and Performance',
      'Vanilla JavaScript Projects: 25 Real-World Applications',
      'JavaScript Testing: Jest, Testing Library, and Playwright',
      'JavaScript Architecture Patterns for Senior Developers',
    ],
    'TypeScript' => [
      'TypeScript Complete Guide: From JavaScript to Full Type Safety',
      'Advanced TypeScript: Generics, Conditional Types, and Template Literals',
      'TypeScript Compiler and Toolchain Configuration',
      'TypeScript Best Practices in Large Enterprise Codebases',
    ],
    'React' => [
      'React 18 Complete Guide: Hooks, Context, and Concurrent Features',
      'Advanced React Patterns: Composition, HOCs, and Render Props',
      'React Performance: Profiling, Memoisation, and Rendering Strategies',
      'React with TypeScript: Production-Ready Development',
      'Next.js 14: Full-Stack React with App Router and Server Actions',
      'React Native: Building Cross-Platform iOS and Android Apps',
      'State Management in React: Redux Toolkit, Zustand, and Jotai',
      'React Testing: Unit, Integration, and End-to-End',
    ],
    'Vue' => [
      'Vue 3 Masterclass: Composition API and Pinia State Management',
      'Nuxt 3: Server-Side Rendering and Full-Stack Vue.js',
      'Vue 3 with TypeScript: Enterprise Application Development',
      'Testing Vue 3 Applications: Vitest and Vue Test Utils',
    ],
    'Node.js' => [
      'Node.js Backend Mastery: APIs, Microservices, and Performance',
      'Node.js Streams and Event-Driven Architecture',
      'Building REST APIs with Express.js and TypeScript',
      'Node.js Security: OWASP Top 10 and Mitigation Strategies',
      'Node.js in Production: Observability, Scaling, and Deployment',
    ],
    'Go' => [
      'Go Programming: From Beginner to Professional Developer',
      'Concurrent Go: Goroutines, Channels, and Concurrency Patterns',
      'Web APIs with Go: Gin, Chi, and Standard Library Approaches',
      'Go for Cloud-Native Development and Microservices',
      'Testing and Benchmarking in Go',
    ],
    'Java' => [
      'Java Complete Masterclass 2024: Zero to Senior Developer',
      'Advanced Java: JVM Internals, GC Tuning, and Performance',
      'Java Concurrency: Thread Safety and Lock-Free Data Structures',
      'Java Design Patterns: GoF and Enterprise Patterns in Practice',
    ],
    'Spring Boot' => [
      'Spring Boot 3: Complete Enterprise Application Development',
      'Spring Security 6: OAuth2, JWT, and Microservices Authorization',
      'Spring Data: JPA, MongoDB, and Redis Integration',
      'Spring Microservices: Resilience, Tracing, and Service Mesh',
    ],
    'AWS' => [
      'AWS Solutions Architect Associate: SAA-C03 Complete Preparation',
      'AWS Developer Associate: DVA-C02 Certification Guide',
      'AWS Advanced: Multi-Account Strategy and Landing Zone',
      'Serverless Architecture on AWS: Lambda, API Gateway, and DynamoDB',
      'AWS Cost Optimisation: FinOps Frameworks and Best Practices',
      'AWS Security Specialty: Encryption, IAM, and Compliance',
    ],
    'Docker' => [
      'Docker Mastery: Complete Container Guide for Developers',
      'Docker Compose: Multi-Container Applications in Practice',
      'Docker in Production: Security, Performance, and Operations',
    ],
    'Kubernetes' => [
      'Kubernetes for Developers: From Containers to Production Clusters',
      'CKA Certification: Certified Kubernetes Administrator',
      'CKAD Preparation: Kubernetes Application Developer',
      'Advanced Kubernetes: Operators, Custom Resources, and GitOps',
      'Kubernetes Security: Pod Security, RBAC, and Network Policies',
    ],
    'CI/CD' => [
      'GitHub Actions: Complete Workflow Automation Guide',
      'GitLab CI/CD: Enterprise Pipeline Engineering',
      'ArgoCD and GitOps: Continuous Delivery for Kubernetes',
      'Jenkins Pipeline: CI/CD at Enterprise Scale',
    ],
    'UI/UX Design' => [
      'Complete UI/UX Design Bootcamp: From Zero to Portfolio',
      'User Research Methods: Interviews, Surveys, and Usability Testing',
      'Design Systems: Building, Documenting, and Maintaining at Scale',
      'Mobile UX: iOS and Android Human Interface Guidelines',
      'Accessibility-First Design: WCAG 2.2 Compliance in Practice',
      'UX Writing: Microcopy, Onboarding, and Interface Language',
    ],
    'Figma' => [
      'Figma Masterclass: UI Design from Wireframe to Interactive Prototype',
      'Advanced Figma: Variables, Auto Layout, and Component Libraries',
      'Figma for Developers: Design Tokens and Developer Handoff',
      'Figma Team Collaboration: Branches, Libraries, and Review Workflows',
    ],
    'Graphic Design' => [
      'Graphic Design Fundamentals: Visual Communication Principles',
      'Logo Design Masterclass: From Brief to Brand Mark',
      'Typography Deep Dive: Pairing, Hierarchy, and Expressive Type',
    ],
    'Adobe Photoshop' => [
      'Adobe Photoshop CC: Complete Professional Guide 2024',
      'Photo Retouching and Compositing with Photoshop',
      'Photoshop for UI Designers: Web and App Asset Creation',
    ],
    'Digital Marketing' => [
      'Digital Marketing Complete: SEO, SEM, Social, Email, and Analytics',
      'Technical SEO Mastery: Site Architecture and Search Ranking',
      'Google Ads: Search, Display, and Performance Max Campaigns',
      'Facebook and Instagram Ads: Complete Performance Marketing Guide',
      'Marketing Analytics: GA4, Looker Studio, and Attribution Modelling',
    ],
    'Content Marketing' => [
      'Content Marketing Strategy: Research, Creation, and Distribution',
      'B2B Content Marketing: Driving Pipeline with Long-Form Content',
      'Video Content Strategy: YouTube, Short-Form, and Social Video',
    ],
    'Email Marketing' => [
      'Email Marketing Automation: HubSpot, Klaviyo, and Mailchimp',
      'Email Deliverability: Reaching the Inbox at Scale',
      'Email Programme Optimisation: Open Rates, CTR, and Revenue',
    ],
    'Product Management' => [
      'Product Management Certification: Complete PM Career Preparation',
      'Agile Product Management: Scrum, Kanban, and OKRs in Practice',
      'Product Analytics: Building a Data-Informed Decision Culture',
      'Technical Product Management for Engineering Backgrounds',
      'Product Strategy: From Vision to Measurable Outcomes',
      'B2B SaaS Product Management: Discovery, Delivery, and Growth',
    ],
    'Tiếng Nhật' => [
      'JLPT N5: Tiếng Nhật từ con số 0 — Khóa học toàn diện',
      'JLPT N4: Ngữ pháp và từ vựng sơ cấp tiếng Nhật',
      'JLPT N3: Luyện thi năng lực Nhật ngữ trung cấp',
      'JLPT N2: Tiếng Nhật thương mại cho người đi làm',
      'Hiragana và Katakana thành thạo trong 21 ngày',
      'Tiếng Nhật giao tiếp: Hội thoại tự nhiên và thực tế',
      'Kanji hệ thống: Từ N5 đến N2 theo phương pháp ghi nhớ hiệu quả',
      'Tiếng Nhật thương mại: Giao tiếp chuyên nghiệp tại môi trường doanh nghiệp',
      'Nghe hiểu tiếng Nhật: Luyện kỹ năng nghe từ N4 đến N2',
      'Tiếng Nhật cho ngành IT: Từ vựng kỹ thuật và môi trường làm việc',
    ],
    'Tiếng Anh' => [
      'Business English Communication: Writing, Email, and Presentation',
      'Advanced English Grammar for Non-Native Professionals',
      'English Pronunciation: American Accent and Intonation Training',
      'Academic Writing in English: Essays, Reports, and Research Papers',
      'English for IT and Technology: Technical Communication',
      'Business Email and Workplace English',
      'English Public Speaking and Persuasive Presentation',
    ],
    'IELTS' => [
      'IELTS Complete Preparation: Target Band 7.0 and Above',
      'IELTS Academic Writing: Band 8 Strategies for Task 1 and 2',
      'IELTS Speaking: Fluency, Coherence, and Lexical Resource',
      'IELTS Listening and Reading: Speed and Accuracy Techniques',
    ],
    'TOEIC' => [
      'TOEIC 900+ Complete Preparation: Listening and Reading',
      'TOEIC Part 5–7 Reading: Grammar, Vocabulary, and Comprehension',
      'TOEIC Listening Parts 1–4: Strategies for High Scores',
    ],
    'Tiếng Hàn' => [
      'Tiếng Hàn từ đầu: Hangul đến hội thoại cơ bản',
      'TOPIK I và II: Luyện thi năng lực tiếng Hàn toàn diện',
      'Tiếng Hàn thương mại: Giao tiếp chuyên nghiệp',
      'Tiếng Hàn qua K-Drama và K-Pop',
    ],
    'Phân tích tài chính' => [
      'Financial Analysis Masterclass: Statements, Valuation, and Modelling',
      'Corporate Finance: Capital Structure, Investment, and M&A',
      'Financial Modelling with Excel: DCF, LBO, and Comparable Analysis',
      'CFA Level 1 Complete Preparation Programme',
      'Credit Analysis and Fixed Income Securities',
    ],
    'Đầu tư chứng khoán' => [
      'Stock Market Investment: Fundamental and Technical Analysis',
      'Đầu tư chứng khoán Việt Nam: Phân tích cơ bản và kỹ thuật',
      'Portfolio Construction and Risk Management',
      'Derivatives Trading: Options, Futures, and Risk',
    ],
    'Cryptocurrency & Blockchain' => [
      'Blockchain and Cryptocurrency: Complete Investor and Developer Guide',
      'DeFi: Decentralised Finance from Concept to Strategy',
      'Crypto Trading: Technical Analysis and Risk Management',
    ],
    'Data Analysis' => [
      'Data Analysis with Python: Pandas, NumPy, and Visualisation',
      'SQL for Data Analysis: Window Functions and Query Optimisation',
      'Excel Power User: Pivot Tables, Power Query, and VBA',
      'Exploratory Data Analysis: From Raw Data to Actionable Insights',
      'Statistical Analysis with R: From Descriptive to Inferential',
    ],
    'Business Intelligence' => [
      'Tableau Desktop: Complete Data Visualisation and Dashboard Guide',
      'Power BI: From Data Model to Executive Dashboard',
      'Data Warehouse Design: Dimensional Modelling and Star Schema',
    ],
    'Kế toán' => [
      'Kế toán doanh nghiệp Việt Nam: Từ cơ bản đến nâng cao',
      'Phần mềm kế toán MISA SME: Hướng dẫn thực hành toàn diện',
      'Kiểm toán nội bộ: Quy trình, phương pháp và báo cáo',
    ],
    'Quản lý dự án' => [
      'Project Management Professional (PMP) Certification Preparation',
      'Agile và Scrum thực chiến: Sprint Planning đến Retrospective',
      'Quản lý dự án CNTT: Từ yêu cầu đến nghiệm thu',
    ],
    'Khởi nghiệp' => [
      'Khởi nghiệp từ Zero: Ý tưởng, Validation và MVP',
      'Startup Fundraising: Pitch Deck, Term Sheet, và Deal Flow',
      'Lean Startup trong thực tế: Build, Measure, Learn',
    ],
    'Adobe Premiere Pro' => [
      'Adobe Premiere Pro: Professional Video Editing Complete Course',
      'Premiere Pro for YouTube Creators: Fast Editing Workflow',
    ],
    'DaVinci Resolve' => [
      'DaVinci Resolve 18: Professional Colour Grading and Editing',
      'DaVinci Resolve Fusion: Motion Graphics and Visual Effects',
    ],
    'After Effects' => [
      'After Effects Masterclass: Motion Graphics and Visual Effects',
      'After Effects for UI Designers: Micro-Animations and Prototypes',
    ],
    'Kỹ năng giao tiếp' => [
      'Kỹ năng giao tiếp và thuyết trình chuyên nghiệp',
      'Tư duy phản biện và giải quyết vấn đề trong công việc',
      'Nghệ thuật đàm phán và thuyết phục',
    ],
  }.freeze

  # ── Module templates ──────────────────────────────────────
  MODULE_TEMPLATES = {
    default: [
      ['Introduction & Course Overview', [
        'Welcome and Course Roadmap',
        'Prerequisites and Environment Setup',
        'Core Concepts You Need to Know First',
      ]],
      ['Foundations', [
        'Fundamental Theory',
        'Key Terminology and Mental Models',
        'Your First Hands-On Example',
        'Common Mistakes and How to Avoid Them',
      ]],
      ['Core Skills', [
        'Building Block One',
        'Building Block Two',
        'Combining Concepts: Practical Walkthrough',
        'Exercises and Self-Assessment',
      ]],
      ['Intermediate Techniques', [
        'Going Deeper: Advanced Patterns',
        'Real-World Application',
        'Debugging and Troubleshooting',
        'Performance and Optimisation Considerations',
      ]],
      ['Advanced Topics', [
        'Expert-Level Patterns',
        'Edge Cases and Production Concerns',
        'Integration with the Broader Ecosystem',
      ]],
      ['Capstone Project', [
        'Project Brief and Requirements',
        'Architecture and Design Decisions',
        'Implementation Walkthrough',
        'Testing and Quality Assurance',
        'Deployment and Next Steps',
      ]],
    ],
  }.freeze

  LESSON_TYPES_BY_CATEGORY = {
    'Tiếng Nhật' => :language,
    'Tiếng Anh'  => :language,
    'IELTS'      => :language,
    'TOEIC'      => :language,
    'Tiếng Hàn'  => :language,
  }.freeze

  DESCRIPTIONS = [
    "This comprehensive course takes you from the fundamentals to advanced, production-ready skills. Each module builds logically on the previous, ensuring a smooth learning progression without gaps. The curriculum was developed from years of industry experience and refined through feedback from thousands of learners.",
    "Built for practitioners who want to move beyond surface-level understanding. This course explains not just *how* things work, but *why* — giving you mental models to solve problems you have never seen before. Real-world projects throughout reinforce every major concept.",
    "This course distils years of professional experience into a carefully structured learning path. Content is regularly updated to reflect current industry practices, ensuring what you learn is immediately relevant. The capstone project simulates a real-world challenge from start to finish.",
    "Whether you are entering this field for the first time or deepening existing expertise, this course meets you where you are. The first half establishes a rock-solid foundation; the second half pushes into advanced territory that sets high-performers apart from the rest.",
    "Professionally produced with clear explanations, well-paced lessons, and hands-on exercises designed to build genuine competency — not just assessment scores. The Q&A section is actively monitored by the instructor and community.",
  ].freeze

  def self.run!
    now = SeedHelpers::NOW
    instructors = User.where(role: 'instructor').to_a
    leaf_cats   = Category.where.not(parent_id: nil).to_a

    courses_batch  = []
    outcomes_batch = []
    course_idx     = 0

    leaf_cats.each do |cat|
      titles = TITLES[cat.name] || []
      next if titles.empty?

      titles.each do |title|
        break if course_idx >= 550
        instructor = instructors.sample

        price = case rand(10)
                when 0..5 then (rand(300..2499) * 1000).round(-3)   # Standard
                when 6..8 then (rand(2500..4999) * 1000).round(-3)  # Professional
                else           (rand(5000..9999) * 1000).round(-3)  # Premium
                end

        created = SeedHelpers.rand_time(SeedHelpers::THREE_YRS_AGO, SeedHelpers::ONE_YR_AGO)

        courses_batch << {
          category_id:          cat.id,
          title:                title,
          description:          DESCRIPTIONS.sample,
          thumbnail_url:        SeedHelpers.thumbnail(course_idx + 1),
          created_by:           instructor.id,
          price:                price,
          status:               rand(10) < 9 ? Course.statuses[:published] : Course.statuses[:draft],
          allow_admin_discounts: [true, true, true, false].sample,
          created_at:           created,
          updated_at:           SeedHelpers.rand_time(created, now),
        }
        course_idx += 1
      end
    end

    # Fill to 500 if needed
    while course_idx < 500
      cat        = leaf_cats.sample
      instructor = instructors.sample
      created    = SeedHelpers.rand_time(SeedHelpers::THREE_YRS_AGO, SeedHelpers::ONE_YR_AGO)
      courses_batch << {
        category_id:          cat.id,
        title:                "#{cat.name}: Complete Professional Course",
        description:          DESCRIPTIONS.sample,
        thumbnail_url:        SeedHelpers.thumbnail(course_idx + 1),
        created_by:           instructor.id,
        price:                (rand(300..2000) * 1000).round(-3),
        status:               Course.statuses[:published],
        allow_admin_discounts: true,
        created_at:           created,
        updated_at:           SeedHelpers.rand_time(created, now),
      }
      course_idx += 1
    end

    Course.insert_all!(courses_batch)
    all_courses = Course.all.order(:id).to_a
    puts "  ✓ #{all_courses.length} courses created"

    # ── Learning outcomes ────────────────────────────────────
    all_courses.each_with_index do |course, ci|
      outcomes = rand(4..8)
      outcomes.times do |oi|
        outcomes_batch << {
          course_id:   course.id,
          content:     learning_outcome(ci, oi),
          order_index: oi + 1,
          created_at:  course.created_at,
          updated_at:  course.updated_at,
        }
      end
    end
    CourseLearningOutcome.insert_all!(outcomes_batch)
    puts "  ✓ #{outcomes_batch.length} learning outcomes"

    # ── Modules and lessons ──────────────────────────────────
    modules_batch = []
    lessons_batch = []
    lesson_idx    = 0

    all_courses.each_with_index do |course, ci|
      template   = MODULE_TEMPLATES[:default]
      mod_count  = rand(5..9)
      modules_to_use = template.first(mod_count)

      modules_to_use.each_with_index do |(mod_title, lesson_titles), mi|
        modules_batch << {
          course_id:   course.id,
          title:       mod_title,
          description: "#{mod_title} for #{course.title.split(':').first}",
          order_index: mi + 1,
          created_at:  course.created_at,
          updated_at:  course.updated_at,
        }
      end
    end

    CourseModule.insert_all!(modules_batch)
    puts "  ✓ #{modules_batch.length} course modules"

    all_modules = CourseModule.all.order(:course_id, :order_index).to_a

    all_courses.each do |course|
      course_mods = all_modules.select { |m| m.course_id == course.id }
      course_mods.each_with_index do |mod, mi|
        template_lessons = MODULE_TEMPLATES[:default][mi]&.last || ['Introduction', 'Core Concepts', 'Practice']
        lesson_count = [template_lessons.length, rand(3..7)].max

        lesson_count.times do |li|
          title = template_lessons[li] || "Lesson #{li + 1}"
          is_free = (mi == 0 && li == 0)

          lessons_batch << {
            course_module_id:        mod.id,
            title:                   title,
            description:             "In this lesson, you will learn about #{title.downcase}.",
            video_url:               SeedHelpers.yt_embed(lesson_idx),
            order_index:             li + 1,
            free_preview:            is_free,
            lesson_type:             0,  # video
            upload_type:             0,  # youtube
            cached_duration_seconds: rand(600..3600),
            created_at:              course.created_at,
            updated_at:              course.updated_at,
          }
          lesson_idx += 1
        end
      end
    end

    Lesson.insert_all!(lessons_batch)
    puts "  ✓ #{lessons_batch.length} lessons"
  end

  def self.learning_outcome(course_idx, outcome_idx)
    outcomes = [
      'Understand the core principles and be able to explain them clearly to colleagues',
      'Build production-quality implementations that handle real-world edge cases',
      'Design and evaluate alternative approaches with clear tradeoff analysis',
      'Debug and troubleshoot common issues efficiently',
      'Apply best practices and industry standards throughout',
      'Integrate with existing systems and toolchains',
      'Measure performance and optimise for production workloads',
      'Communicate architectural decisions to technical and non-technical stakeholders',
    ]
    outcomes[(course_idx + outcome_idx) % outcomes.length]
  end
  private_class_method :learning_outcome
end
