class WishlistsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_course, only: [:toggle]

  def index
    @pagy, @wishlists = pagy(current_user.wishlists.includes(:course).order(created_at: :desc), items: 12)
  end

  def toggle
    @wishlist = current_user.wishlists.find_by(course: @course)

    if @wishlist
      @wishlist.destroy
      @favorited = false
    else
      current_user.wishlists.create(course: @course)
      @favorited = true
    end

    respond_to do |format|
      format.turbo_stream
      format.html{redirect_back fallback_location: courses_path}
    end
  end

  private

  def set_course
    @course = Course.find(params[:course_id])
  end
end
