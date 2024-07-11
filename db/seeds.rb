require_relative '../app/services/football_data_service'

service = FootballDataService.new

leagues = {
  'Premier League' => 39, 
  'La Liga' => 65,
  'Serie A' => 71,
  'Bundesliga' => 78,
  'Ligue 1' => 61,
  'Eredivisie' => 88
}

leagues.each do |league_name, league_id|
  league = League.find_or_create_by(name: league_name)
  
  response = service.get_teams_for_league(league_id)
  
  if response.success?
    teams = response.parsed_response['response']

    teams.each do |team_data|
      Team.find_or_create_by(
        name: team_data['team']['name'],
        location: team_data['team']['country'],
        year: team_data['team']['founded'],
        league: league
      )
    end
  else
    puts "Błąd: Nie udało się pobrać danych drużyn dla ligi #{league_name}."
    puts "Kod błędu: #{response.code}" if response.code
    puts "Wiadomość błędu: #{response.message}" if response.message
  end
  
  # Dodaj opóźnienie, aby uniknąć przekroczenia limitu zapytań
  sleep(2)
end
