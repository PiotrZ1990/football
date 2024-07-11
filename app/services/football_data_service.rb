class FootballDataService
  include HTTParty
  base_uri 'https://api-football-v1.p.rapidapi.com/v3'
  
  def initialize
    @headers = {
      "X-RapidAPI-Key" => "703b9fe83fca655ad68df6455e60a8ad",
      "X-RapidAPI-Host" => "api-football-v1.p.rapidapi.com"
    }
  end

  def get_teams_for_league(league_id)
    options = { headers: @headers }
    self.class.get("/teams?league=#{league_id}&season=2023", options)
  end
end
