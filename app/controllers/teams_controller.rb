class TeamsController < ApplicationController
  before_action :set_team, only: %i[show edit update destroy history]

  # GET /teams
  def index
    @teams = Team.all
  end

  # GET /teams/1
  def show
  end

  # GET /teams/1/history
  def history
    if @team.league
      matches = @team.league.matches.where("home_team_id = ? OR away_team_id = ?", @team.id, @team.id)
      if matches.any?
        render json: { matches: matches.map { |match| match_details(match) } }
      else
        render json: { message: 'No matches found for this team' }, status: :ok
      end
    else
      render json: { error: 'League not found for this team' }, status: :not_found
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
end
