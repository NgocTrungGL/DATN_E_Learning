class Organization < ApplicationRecord
  has_many :users, dependent: :nullify

  enum plan: {free: 0, standard: 1, enterprise: 2}

  validates :name, presence: true, uniqueness: true
  validates :domain, presence: true
  accepts_nested_attributes_for :users
end
