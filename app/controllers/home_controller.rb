class HomeController < ApplicationController
  # Skip authentication for the public landing page
  def index
    # Load up to 8 featured published courses with associations
    # Easily replaceable with an API call later
    @featured_courses = Course.published
                              .includes(:category, :creator, :reviews)
                              .recent
                              .limit(8)
  end
end
