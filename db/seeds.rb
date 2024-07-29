require 'open-uri'
require 'httparty'
require 'json'
require 'geocoder'

require_relative '../config/environment'

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

    team = Team.find_or_initialize_by(
      name: team_data['team']['name'],
      location: team_data['team']['country'],
      league: league
    )
    
    # Ustal dane tylko dla nowych drużyn
    if team.new_record?
      team.year = team_data['team']['founded']
      team.address = venue['address']
      team.city = venue['city']

      if team_data['team']['logo'].present?
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
          team.lat = geocoded.latitude
          team.lng = geocoded.longitude
          puts "Zaktualizowano współrzędne dla adresu #{team.address}: Lat: #{geocoded.latitude}, Lng: #{geocoded.longitude}"
        else
          puts "Geokodowanie nie powiodło się dla adresu #{team.address}"
        end
      end
    end

    team.save!
    
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

# Metoda do pobierania danych meczów dla danej ligi
def get_matches_for_league(league_id)
  url = "https://v3.football.api-sports.io/fixtures?league=#{league_id}&season=2023"
  headers = {
    "X-RapidAPI-Key" => API_KEY,
    "X-RapidAPI-Host" => API_HOST
  }
  response = HTTParty.get(url, headers: headers)
  response
rescue HTTParty::Error => e
  puts "Błąd HTTP podczas pobierania danych meczów dla ligi #{league_id}: #{e.message}"
  nil
rescue StandardError => e
  puts "Nieoczekiwany błąd podczas pobierania danych meczów dla ligi #{league_id}: #{e.message}"
  nil
end

# Metoda do zapisywania meczów z retry logic
def save_match_with_retry(match_data, league)
  retries = 3
  begin
    home_team = Team.find_by(name: match_data['teams']['home']['name'])
    away_team = Team.find_by(name: match_data['teams']['away']['name'])
    return if home_team.nil? || away_team.nil?

    home_score = match_data['goals']['home']
    away_score = match_data['goals']['away']

    if home_score.nil? || away_score.nil?
      puts "Brak wyniku dla meczu: #{home_team.name} vs #{away_team.name}, pominięcie zapisu."
      return
    end

    # Zakładam, że round_number jest częścią match_data['league']
    round_number = match_data['league']['round'].match(/\d+/)[0].to_i rescue nil

    # Sprawdź, czy mecz już istnieje
    existing_match = Match.find_by(
      league: league,
      season: match_data['league']['season'],
      date: match_data['fixture']['date'],
      home_team: home_team,
      away_team: away_team
    )

    if existing_match
      puts "Mecz pomiędzy #{home_team.name} a #{away_team.name} już istnieje, pominięcie zapisu."
      return
    end

    Match.create!(
      league: league,
      season: match_data['league']['season'],
      date: match_data['fixture']['date'],
      home_team: home_team,
      away_team: away_team,
      home_score: home_score,
      away_score: away_score,
      result: determine_result(home_score, away_score),
      round_number: round_number
    )

  rescue ActiveRecord::StatementInvalid => e
    if retries > 0 && e.message.include?("database is locked")
      retries -= 1
      sleep(1)
      retry
    else
      puts "Nieoczekiwany błąd podczas zapisywania meczu: #{e.message}"
    end
  rescue StandardError => e
    puts "Nieoczekiwany błąd podczas zapisywania meczu: #{e.message}"
  end
end

def determine_result(home_score, away_score)
  if home_score > away_score
    'W'
  elsif home_score < away_score
    'L'
  else
    'D'
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

# Pobierz drużyny i mecze dla każdej ligi i zapisz je do bazy danych
leagues.each do |league_name, league_id|
  league = League.find_or_create_by(name: league_name)
  
  # Pobierz i zapisz drużyny
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

  # Pobierz i zapisz mecze
  response = get_matches_for_league(league_id)
  if response&.success?
    matches = response.parsed_response['response']
    matches.each do |match_data|
      save_match_with_retry(match_data, league)
    end
  else
    puts "Błąd: Nie udało się pobrać danych meczów dla ligi #{league_name}."
    puts "Kod błędu: #{response&.code}" if response&.code
    puts "Wiadomość błędu: #{response&.message}" if response&.message
  end

  sleep(2)
end
