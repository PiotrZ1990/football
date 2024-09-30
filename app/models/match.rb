class Match < ApplicationRecord
  has_many :tickets
  has_many :users, through: :tickets
  belongs_to :league
  belongs_to :home_team, class_name: 'Team'
  belongs_to :away_team, class_name: 'Team'

  def self.predict_betting_odds_for_match(match)
    home_team = match.home_team
    away_team = match.away_team

    # Obliczanie prawdopodobieństwa wygranej
    probabilities = win_probabilities(home_team, away_team)

    # Obliczanie kursów
    home_odds = probabilities[:home_win_probability].zero? ? 0 : (1.0 / probabilities[:home_win_probability])
    away_odds = probabilities[:away_win_probability].zero? ? 0 : (1.0 / probabilities[:away_win_probability])

    # Dostosowanie kursów, jeśli są większe lub równe 2
    home_odds /= 2 if home_odds >= 2
    away_odds /= 2 if away_odds >= 2

    {
      home_odds: home_odds.round(2),
      away_odds: away_odds.round(2)
    }
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
end
