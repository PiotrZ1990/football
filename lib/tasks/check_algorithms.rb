def simulate_betting
  leagues = League.all # Pobierz wszystkie ligi

  leagues.each do |league|
    puts "Rozpoczynam symulację dla ligi: #{league.name}" # Informacja o lidze
    matches = Match.where("CAST(round_number AS INTEGER) BETWEEN ? AND ? AND league_id = ?", 6, 38, league.id).order(:date)

    total_profit = {
      poisson: 0,
      elo: 0,
      combined: 0
    }

    successful_bets = {
      poisson: 0,
      elo: 0,
      combined: 0
    }

    matches.each_with_index do |match, index|
      puts "Pracuję nad meczem o ID: #{match.id} (#{match.home_team.name} vs #{match.away_team.name}) - Mecz #{index + 1} z #{matches.count}"

      poisson_probabilities = Match.win_probabilities(match.home_team, match.away_team)
      elo_probabilities = Match.elo_win_probabilities(match.home_team, match.away_team)

      average_home_win_probability = (poisson_probabilities[:home_win_probability] + elo_probabilities[:home_win_probability]) / 2
      average_away_win_probability = (poisson_probabilities[:away_win_probability] + elo_probabilities[:away_win_probability]) / 2

      next if (poisson_probabilities[:home_win_probability] - poisson_probabilities[:away_win_probability]).abs < 0.29 ||
              (elo_probabilities[:home_win_probability] - elo_probabilities[:away_win_probability]).abs < 0.29 ||
              (average_home_win_probability - average_away_win_probability).abs < 0.29

      total_profit[:poisson] += process_bet(poisson_probabilities, match, successful_bets, :poisson)
      total_profit[:elo] += process_bet(elo_probabilities, match, successful_bets, :elo)

      combined_probabilities = {
        home_win_probability: average_home_win_probability,
        away_win_probability: average_away_win_probability
      }
      total_profit[:combined] += process_bet(combined_probabilities, match, successful_bets, :combined)

      puts "W meczu #{match.home_team.name} - #{match.away_team.name} wygrała drużyna #{determine_winner(match)}."
    end

    display_results(total_profit, successful_bets, matches.count)
  end
end

def run_simulation
  leagues = League.all # Pobierz wszystkie ligi

  leagues.each do |league|
    puts "Rozpoczynam symulację dla ligi: #{league.name}" # Informacja o lidze
    home_win_buckets = Array.new(10, 0)
    away_win_buckets = Array.new(10, 0)

    matches = Match.where("CAST(round_number AS INTEGER) BETWEEN ? AND ? AND league_id = ?", 6, 38, league.id)

    matches.each_with_index do |match, index|
      puts "Pracuję nad meczem o ID: #{match.id} (#{match.home_team.name} vs #{match.away_team.name}) - Mecz #{index + 1} z #{matches.count}"

      poisson_probabilities = Match.win_probabilities(match.home_team, match.away_team)
      elo_probabilities = Match.elo_win_probabilities(match.home_team, match.away_team)

      average_home_win_probability = (poisson_probabilities[:home_win_probability] + elo_probabilities[:home_win_probability]) / 2
      average_away_win_probability = (poisson_probabilities[:away_win_probability] + elo_probabilities[:away_win_probability]) / 2

      home_bucket_index = (average_home_win_probability * 10).to_i
      away_bucket_index = (average_away_win_probability * 10).to_i

      if home_bucket_index >= 0 && home_bucket_index < 10
        home_win_buckets[home_bucket_index] += 1
      end

      if away_bucket_index >= 0 && away_bucket_index < 10
        away_win_buckets[away_bucket_index] += 1
      end
    end

    # Wyświetlanie koszyków w terminalu
    puts "Koszyki wygranych gospodarzy w lidze #{league.name}:"
    home_win_buckets.each_with_index do |count, index|
      puts "Koszyk #{index + 1} (#{(index * 10 + 1)}-#{(index + 1) * 10}%): #{count} wygranych"
    end

    puts "\nKoszyki wygranych gości w lidze #{league.name}:"
    away_win_buckets.each_with_index do |count, index|
      puts "Koszyk #{index + 1} (#{(index * 10 + 1)}-#{(index + 1) * 10}%): #{count} wygranych"
    end
  end
end

# Uruchomienie symulacji
run_simulation
simulate_betting
