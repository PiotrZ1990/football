# lib/tasks/check_algorithms.rb

def simulate_betting
  matches = Match.where("CAST(round_number AS INTEGER) BETWEEN ? AND ? AND league_id = ?", 6, 38, 1).order(:date)

  total_profit = {
    poisson: 0,
    elo: 0,
    combined: 0
  }

  # Liczniki trafień
  successful_bets = {
    poisson: 0,
    elo: 0,
    combined: 0
  }

  matches.each do |match|
    puts "Pracuję nad meczem o ID: #{match.id} (#{match.home_team.name} vs #{match.away_team.name})"  # Informacja o meczu

    # Oblicz prawdopodobieństwo dla modelu Poissona
    poisson_probabilities = Match.win_probabilities(match.home_team, match.away_team)

    # Oblicz prawdopodobieństwo dla modelu Elo
    elo_probabilities = Match.elo_win_probabilities(match.home_team, match.away_team)

    # Oblicz kursy combined
    average_home_win_probability = (poisson_probabilities[:home_win_probability] + elo_probabilities[:home_win_probability]) / 2
    average_away_win_probability = (poisson_probabilities[:away_win_probability] + elo_probabilities[:away_win_probability]) / 2

    winning_team = determine_winner(match)

    # Ustalamy, na którą drużynę stawiamy i wypisujemy szczegóły
    # Poisson
    if poisson_probabilities[:home_win_probability] > poisson_probabilities[:away_win_probability]
      chosen_team = match.home_team.name
      odds = 1 / poisson_probabilities[:home_win_probability]
      total_profit[:poisson] += calculate_profit(match, :home, odds, 100)
      successful_bets[:poisson] += 1 if winning_team == chosen_team
    else
      chosen_team = match.away_team.name
      odds = 1 / poisson_probabilities[:away_win_probability]
      total_profit[:poisson] += calculate_profit(match, :away, odds, 100)
      successful_bets[:poisson] += 1 if winning_team == chosen_team
    end
    puts "W Poisson stawiam na #{chosen_team} z kursem #{odds.round(2)}"

    # Elo
    if elo_probabilities[:home_win_probability] > elo_probabilities[:away_win_probability]
      chosen_team = match.home_team.name
      odds = 1 / elo_probabilities[:home_win_probability]
      total_profit[:elo] += calculate_profit(match, :home, odds, 100)
      successful_bets[:elo] += 1 if winning_team == chosen_team
    else
      chosen_team = match.away_team.name
      odds = 1 / elo_probabilities[:away_win_probability]
      total_profit[:elo] += calculate_profit(match, :away, odds, 100)
      successful_bets[:elo] += 1 if winning_team == chosen_team
    end
    puts "W Elo stawiam na #{chosen_team} z kursem #{odds.round(2)}"

    # Kombinacja
    if average_home_win_probability > average_away_win_probability
      chosen_team = match.home_team.name
      odds = 1 / average_home_win_probability
      total_profit[:combined] += calculate_profit(match, :home, odds, 100)
      successful_bets[:combined] += 1 if winning_team == chosen_team
    else
      chosen_team = match.away_team.name
      odds = 1 / average_away_win_probability
      total_profit[:combined] += calculate_profit(match, :away, odds, 100)
      successful_bets[:combined] += 1 if winning_team == chosen_team
    end
    puts "W kombinacji stawiam na #{chosen_team} z kursem #{odds.round(2)}"

    puts "W meczu #{match.home_team.name} - #{match.away_team.name} wygrała drużyna #{winning_team}."
  end

  puts "Wyniki symulacji:"
  puts "Profit Poisson: #{total_profit[:poisson].round(2)} PLN"
  puts "Profit Elo: #{total_profit[:elo].round(2)} PLN"
  puts "Profit Combined: #{total_profit[:combined].round(2)} PLN"

  # Wyświetlenie liczby trafnych obstawień
  total_matches = matches.count
  puts "Liczba meczów: #{total_matches}"
  puts "Trafne obstawienia Poisson: #{successful_bets[:poisson]} na #{total_matches} (#{(successful_bets[:poisson].to_f / total_matches * 100).round(2)}%)"
  puts "Trafne obstawienia Elo: #{successful_bets[:elo]} na #{total_matches} (#{(successful_bets[:elo].to_f / total_matches * 100).round(2)}%)"
  puts "Trafne obstawienia Kombinacja: #{successful_bets[:combined]} na #{total_matches} (#{(successful_bets[:combined].to_f / total_matches * 100).round(2)}%)"
end

def calculate_profit(match, bet_on_team, odds, investment)
  actual_result = if match.home_score > match.away_score
                    :home
                  elsif match.away_score > match.home_score
                    :away
                  else
                    :draw
                  end

  if actual_result == bet_on_team
    (odds * investment) - investment
  else
    -investment
  end
end

def determine_winner(match)
  if match.home_score > match.away_score
    match.home_team.name
  elsif match.away_score > match.home_score
    match.away_team.name
  else
    "Remis"
  end
end

simulate_betting
