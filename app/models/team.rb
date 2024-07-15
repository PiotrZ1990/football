class Team < ApplicationRecord
  belongs_to :league
  has_one_attached :logo

  validates :name, :location, :year, presence: true
end
