class Business::EmployeesController < ApplicationController
  before_action :authenticate_user!
  before_action :require_company_admin!
  layout "business"

  def index
    @employees = current_user
                 .organization.users
                 .where(role: :employee)
                 .order(created_at: :desc)
  end

  def new
    @employee = User.new
  end

  def create
    @employee = User.new(employee_params)
    @employee.organization = current_user.organization
    @employee.role = :employee

    if @employee.save
      redirect_to business_employees_path,
                  notice: "Đã thêm nhân viên #{@employee.name} thành công."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @employee = current_user.organization.users.find(params[:id])
  end

  def update
    @employee = current_user.organization.users.find(params[:id])

    if @employee.update(employee_update_params)
      redirect_to business_employees_path,
                  notice: "Cập nhật thông tin thành công."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @employee = current_user.organization.users.find(params[:id])
    @employee.destroy
    redirect_to business_employees_path,
                notice: "Đã xóa nhân viên khỏi hệ thống."
  end

  private

  def require_company_admin!
    return if current_user.company_admin?

    redirect_to root_path, alert: "Không có quyền truy cập."
  end

  def employee_params
    params.require(:user).permit(:name, :email, :password,
                                 :password_confirmation)
  end

  def employee_update_params
    params.require(:user).permit(:name, :email)
  end
end
