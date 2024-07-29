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
end
