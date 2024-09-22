class Team < ApplicationRecord
  # Associations
  belongs_to :league
  has_many :home_matches, class_name: 'Match', foreign_key: 'home_team_id'
  has_many :away_matches, class_name: 'Match', foreign_key: 'away_team_id'
  has_one_attached :logo

  # Validations
  validates :name, :location, :year, :address, :city, presence: true

  # Geocoding
  geocoded_by :address
  after_validation :geocode, if: :will_save_change_to_address?

  def logo_url
    Rails.application.routes.url_helpers.rails_blob_url(logo, only_path: true) if logo.attached?
  end

  # Optional: log geocoding errors
  def geocode
    super
  rescue StandardError => e
    Rails.logger.error("Geocoding failed for address #{address}: #{e.message}")
  end

  def points
  wins_count = all_matches.where(result: 'W').count
  draws_count = all_matches.where(result: 'D').count
  (wins_count * 3) + (draws_count * 1)
  end

  def wins
    all_matches.where(result: 'win').count
  end

  def losses
    all_matches.where(result: 'loss').count
  end

  def draws
    all_matches.where(result: 'draw').count
  end

  def goals_scored
    home_matches.sum(:home_score) + away_matches.sum(:away_score)
  end

  def goals_conceded
    home_matches.sum(:away_score) + away_matches.sum(:home_score)
  end

  def all_matches
    Match.where(home_team: self).or(Match.where(away_team: self))
  end
end
