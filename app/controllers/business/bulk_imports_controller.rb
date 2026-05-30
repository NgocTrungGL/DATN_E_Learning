class Business::BulkImportsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_company_admin!
  layout "business"

  def new
    @import = BulkImport.new
  end

  def create
    file = import_params[:file]
    unless file&.content_type&.include?("csv")
      redirect_to new_business_bulk_import_path, alert: "Please upload a CSV file."
      return
    end

    service = EmployeeImportService.new(
      current_user.organization,
      file.read.force_encoding("UTF-8"),
      current_user
    )

    @results = service.call

    if @results[:imported].any?
      redirect_to business_employees_path,
                  notice: "Imported #{@results[:imported].count} employees successfully." +
                          (@results[:failed].any? ? " #{@results[:failed].count} failed." : ".")
    else
      @import = BulkImport.new
      flash[:alert] = "Import failed. Please check your CSV file."
      render :new, status: :unprocessable_entity
    end
  end

  def template
    csv_data = "email,name,phone,department\n"
    csv_data += "nguyenvana@company.com,Nguyen Van A,0901234567,Engineering\n"
    csv_data += "tranvanb@company.com,Tran Van B,0902345678,Marketing\n"

    send_data csv_data, filename: "employee_import_template.csv", type: "text/csv"
  end

  private

  def require_company_admin!
    return if current_user.company_admin?

    redirect_to root_path, alert: "You don't have permission."
  end

  def import_params
    params.require(:bulk_import).permit(:file)
  end
end

class BulkImport
  include ActiveModel::Model
  attr_accessor :file
end
