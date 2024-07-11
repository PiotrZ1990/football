class League < ApplicationRecord
  has_many :teams, dependent: :destroy
  validates :name, presence: true
  validates :country, presence: true
end
