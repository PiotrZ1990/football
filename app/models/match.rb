class Match < ApplicationRecord
  has_many :tickets
  has_many :users, through: :tickets
  belongs_to :league
  belongs_to :home_team, class_name: 'Team'
  belongs_to :away_team, class_name: 'Team'

end
