class CategoriesController < ApplicationController
  before_action :set_category, only: %i(show)
  skip_before_action :authenticate_user!, only: [:index, :show]
  def index
    @categories = Category.all
  end

  # GET /categories/:id
  def show
    @courses = @category.courses.includes(:category)
  end

  private

  def set_category
    @category = Category.find_by(id: params[:id])

    return unless @category.nil?

    redirect_to categories_path
  end
end
