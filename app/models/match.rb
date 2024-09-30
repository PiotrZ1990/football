class Match < ApplicationRecord
  has_many :tickets
  has_many :users, through: :tickets
  belongs_to :league
  belongs_to :home_team, class_name: 'Team'
  belongs_to :away_team, class_name: 'Team'

  after_save :update_elo_ratings

  def self.elo_win_probabilities(home_team, away_team)
    home_rating = home_team.elo_rating
    away_rating = away_team.elo_rating

    expected_home_win = 1.0 / (1 + 10 ** ((away_rating - home_rating) / 400.0))
    expected_away_win = 1.0 / (1 + 10 ** ((home_rating - away_rating) / 400.0))

    {
      home_win_probability: expected_home_win,
      away_win_probability: expected_away_win
    }
  end

  def self.poisson_probabilities(team, opponent, max_goals = 6)
    team_avg_goals = team.home_matches.average(:home_score) || 0
    opponent_avg_goals = opponent.away_matches.average(:away_score) || 0

    return [] if team_avg_goals.zero? || opponent_avg_goals.zero?

    lambda = team_avg_goals * opponent_avg_goals
    probabilities = (0..max_goals).map do |goals|
      (Math.exp(-lambda) * (lambda ** goals)) / factorial(goals)
    end

    probabilities
  end

  # Dodaj metodę do obliczania silni
  def self.factorial(n)
    return 1 if n == 0
    (1..n).reduce(1, :*)
  end

  def self.win_probabilities(home_team, away_team)
    home_probabilities = poisson_probabilities(home_team, away_team)
    away_probabilities = poisson_probabilities(away_team, home_team)

    home_win_probability = 0
    away_win_probability = 0

    home_probabilities.each_with_index do |home_prob, home_goals|
      away_probabilities.each_with_index do |away_prob, away_goals|
        if home_goals > away_goals
          home_win_probability += home_prob * away_prob
        elsif away_goals > home_goals
          away_win_probability += home_prob * away_prob
        end
      end
    end

    {
      home_win_probability: home_win_probability,
      away_win_probability: away_win_probability
    }
  end

  def self.predict_betting_odds_for_match(match)
    home_team = match.home_team
    away_team = match.away_team

    # Obliczanie prawdopodobieństwa wygranej za pomocą obu modeli
    poisson_probabilities = win_probabilities(home_team, away_team)
    elo_probabilities = elo_win_probabilities(home_team, away_team)

    average_home_win_probability = (poisson_probabilities[:home_win_probability] + elo_probabilities[:home_win_probability]) / 2
    average_away_win_probability = (poisson_probabilities[:away_win_probability] + elo_probabilities[:away_win_probability]) / 2

    # Obliczanie kursów
    home_odds = average_home_win_probability.zero? ? 0 : (1.0 / average_home_win_probability)
    away_odds = average_away_win_probability.zero? ? 0 : (1.0 / average_away_win_probability)

    # Obliczanie średnich kursów
    average_home_odds = ((home_odds + (1.0 / poisson_probabilities[:home_win_probability])) / 2).round(2)
    average_away_odds = ((away_odds + (1.0 / poisson_probabilities[:away_win_probability])) / 2).round(2)

    {
      home_odds: home_odds.round(2),
      away_odds: away_odds.round(2),
      average_home_odds: average_home_odds,
      average_away_odds: average_away_odds
    }
  end


  def update_elo_ratings
    return unless home_score && away_score # Upewnij się, że wynik meczu jest dostępny

    home_team = self.home_team
    away_team = self.away_team

    # Obliczanie nowego rankingu Elo dla drużyn na podstawie wyniku meczu
    new_home_rating = calculate_new_elo(home_team, away_team, self.home_score, self.away_score)
    new_away_rating = calculate_new_elo(away_team, home_team, self.away_score, self.home_score)

    # Aktualizacja Elo ratingów w bazie danych
    home_team.update(elo_rating: new_home_rating)
    away_team.update(elo_rating: new_away_rating)
  end

  def calculate_new_elo(team, opponent, team_score, opponent_score, k_factor = 32)
    # Obliczanie oczekiwanego wyniku
    expected_score = 1.0 / (1 + 10 ** ((opponent.elo_rating - team.elo_rating) / 400.0))

    # Obliczanie rzeczywistego wyniku
    actual_score = if team_score > opponent_score
                     1.0
                   elsif team_score < opponent_score
                     0.0
                   else
                     0.5
                   end

    # Aktualizacja Elo
    team.elo_rating + k_factor * (actual_score - expected_score)
  end
end
