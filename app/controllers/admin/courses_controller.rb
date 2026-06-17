class Admin::CoursesController < Admin::BaseController
  def index
    @parent_categories = Category.roots.includes(:subcategories).order(:name)
    search_params = course_search_params
    set_search_filter_state(search_params)
    set_category_filter_state

    @q = Course.includes(:category, :creator)
               .ransack(search_params.except(:category_id, :category_id_eq))

    @pagy, @courses = pagy(
      apply_category_filter(@q.result(distinct: true), search_params)
        .order(status: :asc, created_at: :desc)
    )
  end

  def show
    @big_quizzes = @course.quizzes.big
  end

  def new
    @course = Course.new
    # Build empty learning outcomes for the form
    4.times { @course.course_learning_outcomes.build }
  end

  def create
    @course = Course.new(course_params)
    @course.creator = current_user

    @course.status = :published

    if @course.save
      redirect_to admin_course_path(@course),
                  notice: t("admin.courses.create.success")
    else
      # Ensure at least 4 empty outcomes for the form
      (4 - @course.course_learning_outcomes.size).times { @course.course_learning_outcomes.build }
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # Ensure at least 4 empty outcomes for the form
    @course.course_learning_outcomes.load
    (4 - @course.course_learning_outcomes.size).times { @course.course_learning_outcomes.build }
  end

  def update
    if @course.update(course_params)
      redirect_to admin_course_path(@course),
                  notice: t("admin.courses.update.success")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @course.destroy
      redirect_to admin_courses_path,
                  notice: t("admin.courses.destroy.success")
    else
      error_message = @course.errors.full_messages.join(", ")
      alert_message = error_message
                      .presence || t("admin.courses.destroy.failure")
      redirect_to admin_courses_path, alert: alert_message
    end
  end

  def lessons
    course = Course.find_by(id: params[:id])

    return render json: { error: "Course not found" }, status: :not_found if course.nil?

    @lessons = Lesson.joins(:course_module)
                     .where(course_modules: { course_id: course.id })
                     .order("course_modules.order_index", "lessons.order_index")
                     .select(:id, :title)

    render json: @lessons
  end

  private

  def course_search_params
    return {}.with_indifferent_access unless params[:q].is_a?(ActionController::Parameters)

    params.require(:q).permit(:title_or_description_cont, :category_id,
                              :category_id_eq).to_h.with_indifferent_access
  end

  def apply_category_filter courses, search_params
    return courses if @selected_category_id.blank?

    category = Category.find_by(id: @selected_category_id)
    return courses unless category

    if category.parent_id.nil?
      child_ids = category.subcategories.pluck(:id)
      courses.where(category_id: [category.id] + child_ids)
    else
      courses.where(category_id: category.id)
    end
  end

  def set_search_filter_state search_params
    @course_search_value = search_params[:title_or_description_cont].to_s
    @selected_category_id = selected_category_id(search_params)
    @filters_active = @course_search_value.present? || @selected_category_id.present?
  end

  def set_category_filter_state
    @selected_category = Category.includes(:parent).find_by(id: @selected_category_id)
    @selected_parent_category = selected_parent_category
    @selected_subcategory = @selected_category&.parent_id ? @selected_category : nil
    @selected_parent_subcategories = @selected_parent_category&.subcategories&.order(:name) || Category.none
  end

  def selected_category_id search_params
    search_params[:category_id_eq].presence || search_params[:category_id].presence
  end

  def selected_parent_category
    return nil unless @selected_category

    @selected_category.parent_id.nil? ? @selected_category : @selected_category.parent
  end

  def set_course
    @course = Course.find_by(id: params[:id])

    return unless @course.nil?

    redirect_to admin_courses_path, alert: "Khóa học không tồn tại."
  end

  def course_params
    params.require(:course).permit(:title, :description, :category_id,
                                   :thumbnail_url, :price,
                                   course_learning_outcomes_attributes: [:id, :content, :order_index, :_destroy])
  end
end
