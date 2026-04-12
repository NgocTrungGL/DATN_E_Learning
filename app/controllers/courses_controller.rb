class CoursesController < ApplicationController
  def index
    @page = (params[:page] || 1).to_i
    @per_page = (@page == 1 ? 8 : 12)

    @courses_scope = Course.published.includes(:category, :creator).recent
    @courses_scope = apply_filters(@courses_scope)

    @courses = @courses_scope.offset(current_offset).limit(@per_page)
    @has_more = @courses_scope.offset(current_offset + @per_page).exists?
    @current_filters = course_params

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def show
    @course = Course.published
                    .includes(course_modules: :lessons).find_by(id: params[:id])

    if @course.nil?
      redirect_to courses_path,
                  alert: "Khóa học không tồn tại hoặc chưa được công khai."
      return
    end

    @big_quizzes = @course.quizzes.big
  end

  private

  # Page 1: 0. Page 2: 8. Page 3: 20. (8 + (page-2)*12)
  def current_offset
    @page == 1 ? 0 : 8 + (@page - 2) * 12
  end

  def apply_filters scope
    if params[:query].present?
      scope = scope.where("title LIKE ?", "%#{params[:query]}%")
    end

    if params[:category_id].present?
      scope = scope.where(category_id: params[:category_id])
    end

    scope = apply_price_filter(scope)
    apply_rating_filter(scope)
  end

  def apply_price_filter scope
    return scope if params[:price_filter].blank?

    if params[:price_filter] == "free"
      scope.where(price: 0)
    else
      scope.where("price > 0")
    end
  end

  def apply_rating_filter scope
    return scope if params[:min_rating].blank?

    scope.left_joins(:reviews).group(:id)
         .having("AVG(reviews.rating) >= ?", params[:min_rating])
  end

  def course_params
    params.permit(:query, :category_id, :price_filter, :min_rating).to_h
  end
end
