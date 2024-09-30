class MatchesController < ApplicationController
  before_action :authenticate_user!, only: [:new, :create]

  def index
    @matches = Match.all
  end

  def show
    @match = Match.find(params[:id])
    @tickets = @match.tickets

    # Dodanie przewidywania kursów
    if params[:predict] = 
      home_team = @match.home_team
      away_team = @match.away_team
      @home_prob = Match.poisson_probabilities(home_team, away_team)
      @away_prob = Match.poisson_probabilities(away_team, home_team)
      @odds = Match.predict_betting_odds_for_match(@match)
    end
  end

  def new
    @match = Match.new
  end

  def create
    @match = Match.new(match_params)
    if @match.save
      redirect_to @match, notice: 'Match was successfully created.'
    else
      render :new
    end
  end

  private

  def match_params
    params.require(:match).permit(:team1_id, :team2_id, :date, :location)
  end
end
