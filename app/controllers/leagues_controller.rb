require 'chunky_png'

class LeaguesController < ApplicationController
  before_action :set_league, only: %i[show edit update destroy compare_teams]

  # GET /leagues
  # GET /leagues.json
  def index
    @leagues = League.all
  end

  # GET /leagues/1
  # GET /leagues/1.json
  def show
    @league = League.find(params[:id])
    @teams = @league.teams

    @home_wins_buckets = Hash.new(0)
    @away_wins_buckets = Hash.new(0)
    
    case @league.id
    when 1
      @home_wins_buckets = {
        "1-10%" => 0,
        "11-20%" => 0,
        "21-30%" => 33,
        "31-40%" => 87,
        "41-50%" => 91,
        "51-60%" => 68,
        "61-70%" => 47,
        "71-80%" => 4,
        "81-90%" => 0,
        "91-100%" => 0
      }
      @away_wins_buckets = {
        "1-10%" => 0,
        "11-20%" => 0,
        "21-30%" => 39,
        "31-40%" => 76,
        "41-50%" => 94,
        "51-60%" => 75,
        "61-70%" => 44,
        "71-80%" => 2,
        "81-90%" => 0,
        "91-100%" => 0
      }
    when 2
      @home_wins_buckets = {
        "1-10%" => 0,
        "11-20%" => 0,
        "21-30%" => 11,
        "31-40%" => 73,
        "41-50%" => 145,
        "51-60%" => 64,
        "61-70%" => 14,
        "71-80%" => 0,
        "81-90%" => 0,
        "91-100%" => 0
      }
      @away_wins_buckets = {
        "1-10%" => 0,
        "11-20%" => 0,
        "21-30%" => 13,
        "31-40%" => 73,
        "41-50%" => 151,
        "51-60%" => 59,
        "61-70%" => 11,
        "71-80%" => 0,
        "81-90%" => 0,
        "91-100%" => 0
      }
    when 3
      @home_wins_buckets = {
        "1-10%" => 0,
        "11-20%" => 0,
        "21-30%" => 22,
        "31-40%" => 90,
        "41-50%" => 127,
        "51-60%" => 78,
        "61-70%" => 13,
        "71-80%" => 0,
        "81-90%" => 0,
        "91-100%" => 0
      }
      @away_wins_buckets = {
        "1-10%" => 0,
        "11-20%" => 0,
        "21-30%" => 24,
        "31-40%" => 92,
        "41-50%" => 126,
        "51-60%" => 74,
        "61-70%" => 14,
        "71-80%" => 0,
        "81-90%" => 0,
        "91-100%" => 0
      }
    when 4
      @home_wins_buckets = {
        "1-10%" => 0,
        "11-20%" => 4,
        "21-30%" => 18,
        "31-40%" => 37,
        "41-50%" => 45,
        "51-60%" => 32,
        "61-70%" => 17,
        "71-80%" => 2,
        "81-90%" => 0,
        "91-100%" => 0
      }
      @away_wins_buckets = {
        "1-10%" => 0,
        "11-20%" => 2,
        "21-30%" => 18,
        "31-40%" => 37,
        "41-50%" => 44,
        "51-60%" => 34,
        "61-70%" => 16,
        "71-80%" => 4,
        "81-90%" => 0,
        "91-100%" => 0
      }
    when 5
      @home_wins_buckets = {
        "1-10%" => 0,
        "11-20%" => 0,
        "21-30%" => 14,
        "31-40%" => 79,
        "41-50%" => 91,
        "51-60%" => 64,
        "61-70%" => 13,
        "71-80%" => 0,
        "81-90%" => 0,
        "91-100%" => 0
      }
      @away_wins_buckets = {
        "1-10%" => 0,
        "11-20%" => 0,
        "21-30%" => 12,
        "31-40%" => 81,
        "41-50%" => 92,
        "51-60%" => 62,
        "61-70%" => 14,
        "71-80%" => 0,
        "81-90%" => 0,
        "91-100%" => 0
      }
    when 6
      @home_wins_buckets = {
        "1-10%" => 0,
        "11-20%" => 2,
        "21-30%" => 24,
        "31-40%" => 69,
        "41-50%" => 68,
        "51-60%" => 70,
        "61-70%" => 23,
        "71-80%" => 5,
        "81-90%" => 0,
        "91-100%" => 0
      }
      @away_wins_buckets = {
        "1-10%" => 0,
        "11-20%" => 2,
        "21-30%" => 25,
        "31-40%" => 65,
        "41-50%" => 69,
        "51-60%" => 72,
        "61-70%" => 22,
        "71-80%" => 6,
        "81-90%" => 0,
        "91-100%" => 0
      }
    end
  end

  # GET /leagues/new
  def new
    @league = League.new
  end

  # GET /leagues/1/edit
  def edit
  end

  # POST /leagues
  # POST /leagues.json
  def create
    @league = League.new(league_params)

    respond_to do |format|
      if @league.save
        format.html { redirect_to league_url(@league), notice: "League was successfully created." }
        format.json { render :show, status: :created, location: @league }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @league.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /leagues/1
  def update
    respond_to do |format|
      if @league.update(league_params)
        format.html { redirect_to league_url(@league), notice: "League was successfully updated." }
        format.json { render :show, status: :ok, location: @league }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @league.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /leagues/1
  def destroy
    @league.destroy

    respond_to do |format|
      format.html { redirect_to leagues_url, notice: "League was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def compare_teams
    if params[:team_ids].present?
      @teams = Team.where(id: params[:team_ids])

      @team_stats = @teams.map do |team|
        {
          team: team,
          matches: team.all_matches.count,
          wins: team.all_matches.where(result: 'W').count,
          losses: team.all_matches.where(result: 'L').count,
          draws: team.all_matches.where(result: 'D').count,
          points: team.points,
          goals_scored: team.goals_scored,
          goals_conceded: team.goals_conceded,
          points_over_time: team.home_matches.or(team.away_matches).order(:date).map do |match|
            [match.date.strftime('%Y-%m-%d'), team.points_for_match(match)]
          end,
          cumulative_points: team.calculate_cumulative_points
        }
      end

      # Zbierz wszystkie unikalne daty
      all_dates = @team_stats.flat_map { |stats| stats[:points_over_time].map { |point| point[0] } }.uniq.sort

      # Uzupełnij brakujące punkty
      @team_stats.each do |stats|
        points_over_time_data = stats[:points_over_time].to_h
        complete_data = all_dates.map { |date| [date, points_over_time_data[date] || 0] }
        stats[:points_over_time] = complete_data
      end

      @points_over_time = @team_stats.map { |stats| { name: stats[:team].name, data: stats[:points_over_time] } }
      @cumulative_points = @team_stats.map { |stats| { name: stats[:team].name, data: stats[:cumulative_points] } }

      render :compare_teams
    else
      redirect_to league_path(params[:league_id]), alert: 'No teams selected for comparison.'
    end
  end

  private

  def set_league
    @league = League.includes(:teams).find(params[:id])
  end

  def league_params
    params.require(:league).permit(:name, :country, :logo)
  end
end
