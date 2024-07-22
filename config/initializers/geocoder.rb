Geocoder.configure(
  lookup: :geoapify,
  api_key: 'bef1801d9eaf4fa694fcc367a56e31ed', # Wstaw swój klucz API z Geoapify
  timeout: 10, # Czas oczekiwania na odpowiedź
  use_https: true, # Używaj HTTPS dla bezpieczniejszych połączeń
  language: :en, # Ustaw język na angielski, można zmienić na inne obsługiwane języki
  # Opcjonalnie: logowanie
  logger: Rails.logger
)
