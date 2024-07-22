require 'open-uri'
require 'httparty'
require 'json'
require 'geocoder'

# Definiowanie kluczy API
API_KEY = 'fd4f51d1f37933186594c51db37a20e9'
API_HOST = 'api-football-v1.p.rapidapi.com'

# Funkcja czyszcząca adres
def clean_address(address)
  address = address.gsub('&apos;', "'").gsub('&amp;', '&')
  address = address.gsub(/[^\w\s,.-]/, '')
  address.strip!
  address
end

# Metoda do pobierania drużyn dla danej ligi
def get_teams_for_league(league_id)
  url = "https://v3.football.api-sports.io/teams?league=#{league_id}&season=2023"
  headers = {
    "X-RapidAPI-Key" => API_KEY,
    "X-RapidAPI-Host" => API_HOST
  }
  response = HTTParty.get(url, headers: headers)
  response
rescue HTTParty::Error => e
  puts "Błąd HTTP podczas pobierania danych dla ligi #{league_id}: #{e.message}"
  nil
rescue StandardError => e
  puts "Nieoczekiwany błąd podczas pobierania danych dla ligi #{league_id}: #{e.message}"
  nil
end

# Metoda do zapisania drużyny z retry logic
def save_team_with_retry(team_data, league)
  retries = 3
  begin
    venue = team_data['venue'] || {}
    address = clean_address("#{venue['address']}, #{venue['city']}")

    team = Team.find_or_create_by(
      name: team_data['team']['name'],
      location: team_data['team']['country'],
      year: team_data['team']['founded'],
      league: league,
      address: venue['address'],
      city: venue['city']
    )

    if team_data['team']['logo'].present? && !team.logo.attached?
      logo_url = team_data['team']['logo']
      downloaded_logo = URI.open(logo_url)
      team.logo.attach(io: downloaded_logo, filename: "#{team_data['team']['name']}_logo.jpg")
    end

    # Geokodowanie adresu i aktualizacja lat/lng
    if team.address.present?
      address_to_geocode = clean_address(team.address)
      puts "Geokodowanie adresu: #{address_to_geocode}" # Dodaj ten log
      geocoded = Geocoder.search(address_to_geocode).first
      if geocoded
        team.update(
          lat: geocoded.latitude,
          lng: geocoded.longitude
        )
        puts "Zaktualizowano współrzędne dla adresu #{team.address}: Lat: #{geocoded.latitude}, Lng: #{geocoded.longitude}"
      else
        puts "Geokodowanie nie powiodło się dla adresu #{team.address}"
      end
    end
    
  rescue ActiveRecord::StatementInvalid => e
    if retries > 0 && e.message.include?("database is locked")
      retries -= 1
      sleep(1)
      retry
    else
      puts "Nieoczekiwany błąd podczas zapisywania drużyny #{team_data['team']['name']}: #{e.message}"
    end
  rescue OpenURI::HTTPError => e
    puts "Błąd HTTP podczas pobierania logo dla drużyny #{team_data['team']['name']}: #{e.message}"
  rescue StandardError => e
    puts "Nieoczekiwany błąd podczas zapisywania drużyny #{team_data['team']['name']}: #{e.message}"
  end
end

# Lista lig z ich ID
leagues = {
  'Premier League' => 39, 
  'Major League Soccer' => 253,
  'Serie A' => 135,
  'Bundesliga' => 78,
  'Ligue 1' => 61,
  'Eredivisie' => 88
}

# Pobierz drużyny dla każdej ligi i zapisz je do bazy danych
leagues.each do |league_name, league_id|
  league = League.find_or_create_by(name: league_name)
  
  response = get_teams_for_league(league_id)
  
  if response&.success?
    teams = response.parsed_response['response']

    teams.each do |team_data|
      save_team_with_retry(team_data, league)
    end
  else
    puts "Błąd: Nie udało się pobrać danych drużyn dla ligi #{league_name}."
    puts "Kod błędu: #{response&.code}" if response&.code
    puts "Wiadomość błędu: #{response&.message}" if response&.message
  end
  
  sleep(2)
end
