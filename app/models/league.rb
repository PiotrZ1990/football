class League < ApplicationRecord
  has_one_attached :logo
  has_many :teams, dependent: :destroy
  has_many :matches

  validates :name, presence: true
  validates :country, presence: true
  validates :image, presence: true, allow_blank: true
end
