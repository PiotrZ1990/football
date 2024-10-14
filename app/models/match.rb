class Match < ApplicationRecord
  has_many :tickets
  has_many :users, through: :tickets
  belongs_to :league
  belongs_to :home_team, class_name: 'Team'
  belongs_to :away_team, class_name: 'Team'

  after_save :update_elo_ratings

  def self.elo_win_probabilities(home_team, away_team)
    calculate_elo_probabilities(home_team.elo_rating, away_team.elo_rating)
  end

  def self.poisson_probabilities(team, opponent, max_goals = 6, last_n_matches = 32)
    team_avg_goals = team.home_matches.order(date: :desc).limit(last_n_matches).average(:home_score) || 0
    opponent_avg_goals = opponent.away_matches.order(date: :desc).limit(last_n_matches).average(:away_score) || 0

    return [] if team_avg_goals.zero? || opponent_avg_goals.zero?

    lambda = team_avg_goals * opponent_avg_goals
    (0..max_goals).map { |goals| poisson_probability(lambda, goals) }
  end

  def self.poisson_probability(lambda, goals)
    (Math.exp(-lambda) * (lambda ** goals)) / factorial(goals)
  end

  def self.factorial(n)
    (1..n).reduce(1, :*) || 1
  end

  def self.win_probabilities(home_team, away_team, last_n_matches = 32)
    home_probabilities = poisson_probabilities(home_team, away_team, last_n_matches)
    away_probabilities = poisson_probabilities(away_team, home_team, last_n_matches)

    calculate_win_probabilities(home_probabilities, away_probabilities)
  end

  def self.calculate_win_probabilities(home_probabilities, away_probabilities)
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

  def self.predict_betting_odds_for_match(match, last_n_matches = 32)
    home_team = match.home_team
    away_team = match.away_team

    poisson_probabilities = win_probabilities(home_team, away_team, last_n_matches)
    elo_probabilities = elo_win_probabilities(home_team, away_team)

    average_odds(poisson_probabilities, elo_probabilities)
  end

  def self.average_odds(poisson_probabilities, elo_probabilities)
    average_home_win_probability = (poisson_probabilities[:home_win_probability] + elo_probabilities[:home_win_probability]) / 2
    average_away_win_probability = (poisson_probabilities[:away_win_probability] + elo_probabilities[:away_win_probability]) / 2

    home_odds = probability_to_odds(average_home_win_probability)
    away_odds = probability_to_odds(average_away_win_probability)

    {
      home_odds: home_odds,
      away_odds: away_odds,
      average_home_odds: ((home_odds + probability_to_odds(poisson_probabilities[:home_win_probability])) / 2).round(2),
      average_away_odds: ((away_odds + probability_to_odds(poisson_probabilities[:away_win_probability])) / 2).round(2)
    }
  end

  def self.probability_to_odds(probability)
    probability.zero? ? 0 : (1.0 / probability).round(2)
  end

  def update_elo_ratings
    return unless home_score && away_score

    update_team_elo(self.home_team, self.away_team, self.home_score, self.away_score)
  end

  def update_team_elo(home_team, away_team, home_score, away_score)
    new_home_rating = calculate_new_elo(home_team, away_team, home_score, away_score)
    new_away_rating = calculate_new_elo(away_team, home_team, away_score, home_score)

    home_team.update(elo_rating: new_home_rating)
    away_team.update(elo_rating: new_away_rating)
  end

  def calculate_new_elo(team, opponent, team_score, opponent_score, k_factor = 32)
    expected_score = calculate_elo_probabilities(team.elo_rating, opponent.elo_rating)[:home_win_probability]
    actual_score = actual_result(team_score, opponent_score)

    team.elo_rating + k_factor * (actual_score - expected_score)
  end

  def actual_result(team_score, opponent_score)
    if team_score > opponent_score
      1.0
    elsif team_score < opponent_score
      0.0
    else
      0.5
    end
  end

  def self.calculate_elo_probabilities(home_rating, away_rating)
    expected_home_win = 1.0 / (1 + 10 ** ((away_rating - home_rating) / 400.0))
    expected_away_win = 1.0 / (1 + 10 ** ((home_rating - away_rating) / 400.0))

    {
      home_win_probability: expected_home_win,
      away_win_probability: expected_away_win
    }
  end
end
