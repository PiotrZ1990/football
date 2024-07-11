class Team < ApplicationRecord
  belongs_to :league
  validates :name, presence: true
  validates :location, presence: true
  validates :year, presence: true
end
