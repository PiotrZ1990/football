# lib/tasks/update_elo.rb

def update_elo_ratings
  k_factor = 32 # Standardowy współczynnik K dla aktualizacji Elo
  matches = Match.order(:date) # Pobieramy mecze w kolejności chronologicznej

  matches.each do |match|
    home_team = match.home_team
    away_team = match.away_team

    home_rating = home_team.elo_rating
    away_rating = away_team.elo_rating

    # Określamy wynik meczu
    if match.home_score > match.away_score
      result = 1 # Wygrana gospodarzy
    elsif match.away_score > match.home_score
      result = 0 # Wygrana gości
    else
      result = 0.5 # Remis
    end

    # Obliczamy oczekiwane wyniki
    expected_home = 1.0 / (1.0 + 10**((away_rating - home_rating) / 400.0))
    expected_away = 1.0 / (1.0 + 10**((home_rating - away_rating) / 400.0))

    # Aktualizujemy rankingi Elo
    new_home_rating = home_rating + k_factor * (result - expected_home)
    new_away_rating = away_rating + k_factor * ((1 - result) - expected_away)

    # Zapisujemy nowe wartości
    home_team.update(elo_rating: new_home_rating)
    away_team.update(elo_rating: new_away_rating)

    puts "Zaktualizowano ranking dla meczu ID: #{match.id} (#{home_team.name} vs #{away_team.name})"
  end

  puts "Aktualizacja rankingów Elo zakończona."
end

update_elo_ratings
