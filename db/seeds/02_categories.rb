# frozen_string_literal: true
# db/seeds/02_categories.rb

module SeedCategories
  STRUCTURE = {
    'Trí tuệ nhân tạo' => [
      'Machine Learning', 'Deep Learning', 'Computer Vision',
      'NLP', 'LLM', 'Prompt Engineering', 'AI Agent', 'RAG Systems',
    ],
    'Lập trình' => [
      'Ruby', 'Ruby on Rails', 'Python', 'JavaScript', 'TypeScript',
      'React', 'Vue', 'Angular', 'Node.js', 'Go', 'Rust',
      'Java', 'Spring Boot', 'PHP', 'Laravel', 'C++', 'C#', 'Swift', 'Kotlin',
    ],
    'Khoa học dữ liệu' => [
      'Data Analysis', 'Data Engineering', 'Business Intelligence',
      'Statistics & Probability', 'Big Data & Spark',
    ],
    'Cloud & DevOps' => [
      'AWS', 'Google Cloud', 'Microsoft Azure',
      'Docker', 'Kubernetes', 'CI/CD', 'Infrastructure as Code',
      'Site Reliability Engineering', 'Linux Administration',
    ],
    'Thiết kế' => [
      'UI/UX Design', 'Figma', 'Adobe Photoshop', 'Adobe Illustrator',
      'Graphic Design', 'Motion Graphics', '3D & Animation',
    ],
    'Marketing số' => [
      'Digital Marketing', 'SEO & SEM', 'Content Marketing',
      'Social Media Marketing', 'Email Marketing', 'Growth Hacking',
      'Marketing Analytics',
    ],
    'Kinh doanh & Quản trị' => [
      'Quản lý dự án', 'Product Management', 'Khởi nghiệp',
      'Lãnh đạo & Quản lý', 'Tài chính doanh nghiệp', 'Agile & Scrum',
    ],
    'Tài chính & Đầu tư' => [
      'Phân tích tài chính', 'Đầu tư chứng khoán', 'Kế toán',
      'Ngân hàng', 'Cryptocurrency & Blockchain',
    ],
    'Ngoại ngữ' => [
      'Tiếng Anh', 'Tiếng Nhật', 'Tiếng Hàn', 'Tiếng Trung',
      'IELTS', 'TOEIC', 'JLPT', 'Tiếng Pháp', 'Tiếng Đức',
    ],
    'Video & Đa phương tiện' => [
      'Adobe Premiere Pro', 'DaVinci Resolve', 'After Effects',
      'YouTube Content Creation', 'Podcast Production',
    ],
    'Phát triển bản thân' => [
      'Kỹ năng giao tiếp', 'Quản lý thời gian', 'Tư duy sáng tạo',
      'Kỹ năng thuyết trình', 'Trí tuệ cảm xúc',
    ],
    'Khoa học & Toán học' => [
      'Toán học', 'Xác suất thống kê', 'Vật lý', 'Hóa học', 'Sinh học',
    ],
  }.freeze

  def self.run!
    now = SeedHelpers::NOW
    parents = {}

    STRUCTURE.keys.each do |name|
      cat = Category.find_or_create_by!(name: name) do |c|
        c.description  = "Khóa học chuyên sâu về #{name}"
        c.created_at   = now
        c.updated_at   = now
      end
      parents[name] = cat
    end
    puts "  ✓ #{parents.size} parent categories"

    child_rows = []
    STRUCTURE.each do |parent_name, children|
      parent = parents[parent_name]
      children.each do |child_name|
        next if Category.exists?(name: child_name)
        child_rows << {
          name:        child_name,
          description: "Chuyên sâu về #{child_name}",
          parent_id:   parent.id,
          created_at:  now,
          updated_at:  now,
        }
      end
    end
    Category.insert_all(child_rows) if child_rows.any?
    puts "  ✓ #{child_rows.size} subcategories, #{Category.count} total"
  end
end
