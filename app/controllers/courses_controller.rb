class CoursesController < ApplicationController
  def index
    set_pagination
    set_sale_courses
    set_course_search
    set_current_filters

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

  def set_pagination
    @page = (params[:page] || 1).to_i
    @per_page = @page == 1 ? 8 : 12
  end

  def set_sale_courses
    @active_global_coupon = Coupon.global.valid.order(discount_value: :desc).first
    return unless @active_global_coupon

    @sale_courses = Course.published.where(allow_admin_discounts: true)
                          .where("price > 0")
                          .order(Arel.sql("RAND()")).limit(4)
  end

  def set_course_search
    @q = Course.published.includes(:category, :creator).ransack(params[:q])
    @courses_scope = @q.result(distinct: true).recent
    @courses = @courses_scope.offset(current_offset).limit(@per_page)
    @has_more = @courses_scope.offset(current_offset + @per_page).exists?
  end

  def set_current_filters
    @current_filters = params.permit(:page, q: {}).to_h
  end

  # Page 1: 0. Page 2: 8. Page 3: 20. (8 + (page-2)*12)
  def current_offset
    @page == 1 ? 0 : 8 + (@page - 2) * 12
  end

  def apply_filters scope
    scope = scope.where("title LIKE ?", "%#{params[:query]}%") if params[:query].present?

    scope = scope.where(category_id: params[:category_id]) if params[:category_id].present?

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
