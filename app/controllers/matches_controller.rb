class MatchesController < ApplicationController
  before_action :authenticate_user!, only: [:new, :create]

  def index
    @matches = Match.all
  end

  def show
    @match = Match.find(params[:id])
    @tickets = @match.tickets
    @odds = nil
    # Dodanie przewidywania kursów
    if params[:predict].present? 
      @odds = Match.predict_betting_odds_for_match(@match)
    end
  end

  def predict_odds
    @match = Match.find(params[:id])
    last_n_matches = params[:num_matches].present? ? params[:num_matches].to_i : 32
    @odds = Match.predict_betting_odds_for_match(@match, last_n_matches)
    
    # Renderuj widok show po obliczeniu kursów
    render :show
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
