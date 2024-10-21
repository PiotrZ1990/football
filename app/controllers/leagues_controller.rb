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
    resize_logo if @league.logo.attached?
    @teams = @league.teams

    # Przygotowanie danych do histogramów
    @home_win_buckets = Array.new(10, 0)
    @away_win_buckets = Array.new(10, 0)

    matches = Match.where(league_id: @league.id, round_number: 6..38)

    matches.each do |match|
      # Oblicz prawdopodobieństwo wygranej gospodarzy i gości
      poisson_probabilities = Match.win_probabilities(match.home_team, match.away_team)
      elo_probabilities = Match.elo_win_probabilities(match.home_team, match.away_team)

      # Oblicz średnie prawdopodobieństwo
      average_home_win_probability = (poisson_probabilities[:home_win_probability] + elo_probabilities[:home_win_probability]) / 2
      average_away_win_probability = (poisson_probabilities[:away_win_probability] + elo_probabilities[:away_win_probability]) / 2

      # Sprawdź, czy prawdopodobieństwo gospodarza jest powyżej 55%
      if average_home_win_probability > 0.55
        bucket_index = (average_home_win_probability * 100 / 10).to_i - 1
        @home_win_buckets[bucket_index] += 1
      end

      # Sprawdź, czy prawdopodobieństwo gości jest powyżej 55%
      if average_away_win_probability > 0.55
        bucket_index = (average_away_win_probability * 100 / 10).to_i - 1
        @away_win_buckets[bucket_index] += 1
      end
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

      # Uzupełnij brakujące punkty w danych każdej drużyny dla "Points Over Time"
      @team_stats.each do |stats|
        points_over_time_data = stats[:points_over_time].to_h
        complete_data = all_dates.map { |date| [date, points_over_time_data[date] || 0] }
        stats[:points_over_time] = complete_data
      end

      # Uzupełnij brakujące punkty w danych każdej drużyny dla "Cumulative Points"
      @team_stats.each do |stats|
        cumulative_points_data = stats[:cumulative_points].to_h
        cumulative_total = 0 # Zmienna śledząca sumę punktów
        complete_cumulative_data = all_dates.map do |date|
          cumulative_total += (cumulative_points_data[date] || 0)
          [date, cumulative_total]
        end
        stats[:cumulative_points] = complete_cumulative_data
      end

      # Przygotowanie danych do wykresów
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

  # Resize league logo using ChunkyPNG
  def resize_logo
    return unless @league.logo.attached?

    begin
      logo_path = ActiveStorage::Blob.service.path_for(@league.logo.key)

      # Load image using ChunkyPNG
      png = ChunkyPNG::Image.from_file(logo_path)

      # Resize image to fit within 200x200 pixels
      png_resized = png.resize(200, 200)

      # Create a temporary PNG file
      temp_png = Tempfile.new(['resized_logo', '.png'])
      temp_png.binmode

      # Save resized image to temporary file
      png_resized.save(temp_png.path)

      # Attach the resized image as @resized_logo
      @resized_logo_path = temp_png.path

    rescue StandardError => e
      logger.error "Failed to resize logo: #{e.message}"
      # Handle error or notify user
    ensure
      temp_png.close
      temp_png.unlink if temp_png
    end
  end

  # Only allow a list of trusted parameters through.
  def league_params
    params.require(:league).permit(:name, :country, :logo)
  end
end
