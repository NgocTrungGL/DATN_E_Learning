class Organization < ApplicationRecord
  has_many :users, dependent: :nullify
  has_many :licenses, dependent: :destroy
  enum plan: {free: 0, standard: 1, enterprise: 2}

  validates :name, presence: true, uniqueness: true
  validates :domain, presence: true
  accepts_nested_attributes_for :users
  def available_licenses
    licenses.where(status: :available)
  end
end
