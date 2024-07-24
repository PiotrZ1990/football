Geocoder.configure(
  lookup: :geoapify,
  api_key: 'bef1801d9eaf4fa694fcc367a56e31ed', 
  timeout: 10, 
  use_https: true, 
  language: :en, 
  # Opcjonalnie: logowanie
  logger: Rails.logger
)
