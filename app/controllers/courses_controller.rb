class CoursesController < ApplicationController
  def index
    set_pagination
    set_sale_courses
    set_course_search
    set_current_filters
    @parent_categories = Category.roots.order(:name)
    @featured_subcategories = Category.where("parent_id IS NOT NULL")
                                      .order(Category.random_order_sql)
                                      .limit(4)

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def show
    @course = Course.includes(course_modules: :lessons).find_by(id: params[:id])

    if @course.nil?
      redirect_to courses_path,
                  alert: "Khóa học không tồn tại hoặc chưa được công khai."
      return
    end

    unless @course.published? || (user_signed_in? && can?(:manage, @course))
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
                          .order(Course.random_order_sql).limit(4)
  end

  def set_course_search
    q = params[:q]
    q_params = (q.respond_to?(:permit) ? q.permit!.to_h : (q.is_a?(Hash) ? q : {}))

    # @q for view (title search, etc.) without category params
    @q = Course.published.includes(:category, :creator).ransack(q_params.except(:category_id, :category_id_eq))

    filtered_results = apply_all_filters
    @courses_scope = filtered_results.recent
    @courses = @courses_scope.offset(current_offset).limit(@per_page)
    @has_more = @courses_scope.offset(current_offset + @per_page).exists?
  end

  def apply_all_filters
    q = params[:q]
    q_params = (q.respond_to?(:permit) ? q.permit!.to_h : (q.is_a?(Hash) ? q : {}))

    results = Course.published.includes(:category, :creator).ransack(q_params.except(:category_id, :category_id_eq)).result(distinct: true)

    # Handle category filter with subcategories
    results = apply_category_filter(results, q_params)

    # Handle price filter
    price = q_params[:price_filter].presence
    if price == "free"
      results = results.where(price: 0)
    elsif price == "paid"
      results = results.where("price > 0")
    end

    # Handle rating filter
    rating = q_params[:min_rating_filter].presence
    if rating.present?
      results = results.left_joins(:reviews).group(:id).having("AVG(reviews.rating) >= ?", rating.to_f)
    end

    results
  end

  def apply_category_filter(results, q_params)
    category_id = q_params[:category_id].presence || q_params[:category_id_eq].presence
    return results unless category_id.present?

    cat = Category.find_by(id: category_id)
    return results unless cat

    if cat.parent_id.nil?
      child_ids = cat.subcategories.pluck(:id)
      results.where(category_id: [cat.id] + child_ids)
    else
      results.where(category_id: cat.id)
    end
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
