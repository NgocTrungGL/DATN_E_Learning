# Load application.yml vao ENV bang Figaro
# Figairo mac dinh tim config/application.yml tai RAILS_ROOT (neu co)
# Neu khong tim thay, thu tuong minh

config_path = if defined?(Rails) && Rails.respond_to?(:root) && Rails.root
                 Rails.root.join("config", "application.yml")
               else
                 Pathname.new(__dir__).parent.parent.join("config", "application.yml")
               end

if config_path.exist?
  YAML.safe_load(config_path.read).each do |key, value|
    ENV[key] ||= value.to_s unless value.nil?
  end
end

# Kiem tra Cloudinary co day du khong
missing = %w[CLOUDINARY_CLOUD_NAME CLOUDINARY_API_KEY CLOUDINARY_API_SECRET] - ENV.keys
unless missing.empty?
  Rails.logger.warn "Figaro missing keys: #{missing.join(', ')}" if defined?(Rails)
end
