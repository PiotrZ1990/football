class AddUniqueIndexToMatches < ActiveRecord::Migration[6.1]
  def change
    add_index :matches, [:league_id, :season, :date, :home_team_id, :away_team_id], unique: true, name: 'unique_match_index'
  end
end
