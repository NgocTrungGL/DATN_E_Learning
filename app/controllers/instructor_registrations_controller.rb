class InstructorRegistrationsController < ApplicationController
  before_action :authenticate_user!

  def new
    if current_user.instructor_profile&.persisted?
      redirect_to instructor_registration_path
      return
    end

    authorize! :create, InstructorProfile

    @profile = current_user.build_instructor_profile
  end

  def create
    if current_user.instructor_profile.present?
      redirect_to instructor_registration_path
      return
    end

    @profile = current_user.build_instructor_profile(profile_params)
    @profile.status = :pending

    authorize! :create, @profile

    if @profile.save
      redirect_to instructor_registration_path, notice: "Your instructor application has been submitted."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @profile = current_user.instructor_profile

    raise ActiveRecord::RecordNotFound if @profile.nil?

    authorize! :read, @profile
  end

  private

  def profile_params
    params.require(:instructor_profile).permit(
      :bio_detailed, :phone, :linkedin_url, :website_url, :cv_url,
      :bank_name, :bank_account_number, :bank_account_name
    )
  end
end
