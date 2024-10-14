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

    # Pomijamy mecz, jeśli kursy są zbyt podobne, aby zachować spójność z poprzednią wersją
    next if (poisson_probabilities[:home_win_probability] - poisson_probabilities[:away_win_probability]).abs < 0.29 ||
            (elo_probabilities[:home_win_probability] - elo_probabilities[:away_win_probability]).abs < 0.29 ||
            (average_home_win_probability - average_away_win_probability).abs < 0.29

    # Logika dla modelu Poissona
    total_profit[:poisson] += process_bet(poisson_probabilities, match, successful_bets, :poisson)

    # Logika dla modelu Elo
    total_profit[:elo] += process_bet(elo_probabilities, match, successful_bets, :elo)

    # Logika dla modelu Combined
    combined_probabilities = {
      home_win_probability: average_home_win_probability,
      away_win_probability: average_away_win_probability
    }
    total_profit[:combined] += process_bet(combined_probabilities, match, successful_bets, :combined)

    puts "W meczu #{match.home_team.name} - #{match.away_team.name} wygrała drużyna #{determine_winner(match)}."
  end

  display_results(total_profit, successful_bets, matches.count)
end

def process_bet(probabilities, match, successful_bets, method)
  if probabilities[:home_win_probability] > probabilities[:away_win_probability] && probabilities[:home_win_probability] > 0.55
    chosen_team = match.home_team.name
    odds = 1 / probabilities[:home_win_probability]
    profit = calculate_profit(match, :home, odds, 100)
    successful_bets[method] += 1 if determine_winner(match) == chosen_team
    puts "W #{method.to_s.capitalize} stawiam na #{chosen_team} z kursem #{odds.round(2)}"
    profit
  elsif probabilities[:away_win_probability] > 0.55
    chosen_team = match.away_team.name
    odds = 1 / probabilities[:away_win_probability]
    profit = calculate_profit(match, :away, odds, 100)
    successful_bets[method] += 1 if determine_winner(match) == chosen_team
    puts "W #{method.to_s.capitalize} stawiam na #{chosen_team} z kursem #{odds.round(2)}"
    profit
  else
    puts "Pominięto zakład #{method.to_s.capitalize} w meczu o ID: #{match.id} - brak wyraźnego faworyta"
    0
  end
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

def display_results(total_profit, successful_bets, total_matches)
  puts "Wyniki symulacji:"
  puts "Profit Poisson: #{total_profit[:poisson].round(2)} PLN"
  puts "Profit Elo: #{total_profit[:elo].round(2)} PLN"
  puts "Profit Combined: #{total_profit[:combined].round(2)} PLN"

  puts "Liczba meczów: #{total_matches}"
  puts "Trafne obstawienia Poisson: #{successful_bets[:poisson]} na #{total_matches} (#{(successful_bets[:poisson].to_f / total_matches * 100).round(2)}%)"
  puts "Trafne obstawienia Elo: #{successful_bets[:elo]} na #{total_matches} (#{(successful_bets[:elo].to_f / total_matches * 100).round(2)}%)"
  puts "Trafne obstawienia Kombinacja: #{successful_bets[:combined]} na #{total_matches} (#{(successful_bets[:combined].to_f / total_matches * 100).round(2)}%)"
end

simulate_betting
