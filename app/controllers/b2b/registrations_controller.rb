class B2b::RegistrationsController < ApplicationController
  skip_before_action :authenticate_user!, raise: false

  def new
    @organization = Organization.new
    @organization.users.build
  end

  def create
    @organization = Organization.new(organization_params)

    @organization.users.each do |user|
      user.role = :company_admin
    end

    if @organization.save
      user = @organization.users.first
      sign_in(user)

      redirect_to root_path,
                  notice: "Chào mừng #{@organization.name}."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def organization_params
    params.require(:organization).permit(
      :name, :domain,
      users_attributes: [:name, :email, :password, :password_confirmation]
    )
  end
end
