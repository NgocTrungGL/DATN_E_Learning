# config/initializers/pagy.rb
require "pagy/extras/bootstrap"
require "pagy/extras/overflow"

Pagy::DEFAULT[:items] = 10   # từ bản 5 dùng lại key :items (dễ nhớ hơn)
Pagy::DEFAULT[:overflow] = :last_page
