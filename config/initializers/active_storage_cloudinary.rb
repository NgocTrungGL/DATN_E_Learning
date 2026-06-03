# Monkey-patch ActiveStorage configurator to handle CloudinaryHttp

require "active_storage/service"

module ActiveStorage
  class Service::Configurator
    alias_method :original_resolve, :resolve

    def resolve(class_name)
      if class_name.to_s == "CloudinaryHttp"
        # Load from lib/active_storage/cloudinary_http_service.rb
        require "#{Rails.root.join("lib/active_storage/cloudinary_http_service")}"
        ActiveStorage::CloudinaryHttpService
      else
        original_resolve(class_name)
      end
    rescue LoadError => e
      raise "Missing service adapter for #{class_name.inspect}: #{e.message}"
    end
  end
end
