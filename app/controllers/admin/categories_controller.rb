class Admin::CategoriesController < Admin::BaseController
  before_action :set_category, only: %i(show edit update destroy)

  def index
    @pagy, @categories = pagy(Category.order(created_at: :desc))
  end

  def show; end

  def new
    @category = Category.new
  end

  def create
    @category = Category.new(category_params)
    if @category.save
      redirect_to admin_category_path(@category),
                  notice: t("admin.categories.create.success")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @category.update(category_params)
      redirect_to admin_category_path(@category),
                  notice: t("admin.categories.update.success")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @category.destroy
      redirect_to admin_categories_path,
                  notice: t("admin.categories.destroy.success")
    else
      error_message = @category.errors.full_messages.to_sentence

      if error_message.blank?
        error_message = t("admin.categories.destroy.failure")
      end

      redirect_to admin_categories_path, alert: error_message
    end
  end

  private

  def set_category
    @category = Category.find_by(id: params[:id])

    return unless @category.nil?

    redirect_to categories_path
  end

  def category_params
    params.require(:category).permit(:name, :description, :parent_id)
  end
end
