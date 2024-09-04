class TeamsController < ApplicationController
  before_action :set_team, only: %i[show edit update destroy history]
  
  # GET /teams
  def index
    @teams = Team.all
  end

  # GET /teams/1
  def show
    # Przygotowanie danych dla wykresów
    @match_statistics = {
      'Win' => @team.home_matches.where("home_score > away_score").count + @team.away_matches.where("away_score > home_score").count,
      'Loss' => @team.home_matches.where("home_score < away_score").count + @team.away_matches.where("away_score > home_score").count,
      'Draw' => @team.home_matches.where("home_score = away_score").count + @team.away_matches.where("home_score = away_score").count
    }

    @goals_statistics = {
      "Goals Scored" => @team.home_matches.sum(:home_score) + @team.away_matches.sum(:away_score),
      "Goals Conceded" => @team.home_matches.sum(:away_score) + @team.away_matches.sum(:home_score)
    }

    @points_over_time = @team.home_matches.or(@team.away_matches).order(:date).map do |match|
      [match.date.strftime('%Y-%m-%d'), points_for_match(match, @team)]
    end

    @cumulative_points = calculate_cumulative_points(@team)

    @points_over_time = [
      { name: 'Points Over Time', data: @points_over_time }
    ]

    @cumulative_points = [
      { name: 'Cumulative Points', data: @cumulative_points }
    ]
  end

  # GET /teams/1/history
  def history
    if @team.league
      matches = @team.league.matches.where("home_team_id = ? OR away_team_id = ?", @team.id, @team.id)
      league_teams = @team.league.teams

      @match_details = matches.map { |match| match_details(match) }
      @league_teams = league_teams.map { |team| team_details(team) }.sort_by { |team| -team[:points] }

      respond_to do |format|
        format.html # Jeśli używasz HTML, upewnij się, że odpowiedni widok istnieje
        format.json { render json: { matches: @match_details, league_teams: @league_teams } }
      end
    else
      respond_to do |format|
        format.html { render plain: 'League not found for this team', status: :not_found }
        format.json { render json: { error: 'League not found for this team' }, status: :not_found }
      end
    end
  end

  # GET /teams/new
  def new
    @team = Team.new
  end

  # GET /teams/1/edit
  def edit
  end

  # POST /teams
  def create
    @team = Team.new(team_params)

    if @team.save
      redirect_to @team, notice: 'Team was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /teams/1
  def update
    if @team.update(team_params)
      redirect_to @team, notice: 'Team was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /teams/1
  def destroy
    @team.destroy
    redirect_to teams_url, notice: 'Team was successfully destroyed.'
  end

  # GET /teams/export_all_to_excel
  def export_all_to_excel
    workbook = Axlsx::Package.new
    
    # Dodaj arkusz dla każdej ligi
    League.find_each do |league|
      workbook.workbook.add_worksheet(name: league.name) do |sheet|
        # Nagłówki
        sheet.add_row ["Team Name", "City", "Matches Played", "Goals Scored", "Goals Conceded", "Points", "Logo URL",]

        # Dodaj dane drużyn w danej lidze
        league.teams.each do |team|
          matches_played = team.home_matches.count + team.away_matches.count
          goals_scored = team.home_matches.sum(:home_score) + team.away_matches.sum(:away_score)
          goals_conceded = team.home_matches.sum(:away_score) + team.away_matches.sum(:home_score)
          points = (team.home_matches.where('home_score > away_score').count + team.away_matches.where('away_score > home_score').count) * 3 +
                   team.home_matches.where('home_score = away_score').count + team.away_matches.where('home_score = away_score').count

          sheet.add_row [
            team.name,
            team.city,
            matches_played,
            goals_scored,
            goals_conceded,
            points,
            team.logo.attached? ? url_for(team.logo) : 'No Logo',
          ]
        end
      end
    end

    # Zapisz plik do wysłania
    send_data workbook.to_stream.read, filename: "teams_report.xlsx", type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
  end

  private

  def set_team
    @team = Team.find(params[:id])
  end

  def team_params
    params.require(:team).permit(:name, :city, :logo, :lat, :lng)
  end

  def match_details(match)
    {
      home_team: match.home_team.name,
      away_team: match.away_team.name,
      home_score: match.home_score,
      away_score: match.away_score,
      outcome: determine_outcome(match),
      home_team_lat: match.home_team.lat,
      home_team_lng: match.home_team.lng,
      away_team_lat: match.away_team.lat,
      away_team_lng: match.away_team.lng,
      home_team_logo: match.home_team.logo.attached? ? url_for(match.home_team.logo) : nil,
      away_team_logo: match.away_team.logo.attached? ? url_for(match.away_team.logo) : nil
    }
  end

  def determine_outcome(match)
    if match.home_score > match.away_score
      match.home_team_id == @team.id ? 'Win' : 'Loss'
    elsif match.home_score < match.away_score
      match.home_team_id == @team.id ? 'Loss' : 'Win'
    else
      'Draw'
    end
  end

  def team_details(team)
    matches_played = team.home_matches.count + team.away_matches.count
    wins = team.home_matches.where('home_score > away_score').count + team.away_matches.where('away_score > home_score').count
    draws = team.home_matches.where('home_score = away_score').count + team.away_matches.where('home_score = away_score').count
    points = (wins * 3) + draws

    {
      id: team.id,
      name: team.name,
      matches: matches_played,
      wins: wins,
      points: points
    }
  end

  def calculate_points_over_time(team)
    total_points = 0
    matches = team.home_matches.or(team.away_matches).order(:date)
    points_over_time = matches.map do |match|
      total_points += points_for_match(match, team)
      {
        date: match.date.strftime('%Y-%m-%d'),
        points: total_points
      }
    end
    points_over_time
  end

  def calculate_cumulative_points(team)
    total_points = 0
    matches = team.home_matches.or(team.away_matches).order(:date)
    matches.map do |match|
      total_points += points_for_match(match, team)
      [match.date.strftime('%Y-%m-%d'), total_points]
    end
  end

  def points_for_match(match, team)
    if match.home_team_id == team.id
      if match.home_score > match.away_score
        3
      elsif match.home_score == match.away_score
        1
      else
        0
      end
    elsif match.away_team_id == team.id
      if match.away_score > match.home_score
        3
      elsif match.away_score == match.home_score
        1
      else
        0
      end
    else
      0
    end
  end
end
