class RemoveEloRatingFromTeams < ActiveRecord::Migration[7.1]
  def change
    remove_column :teams, :elo_rating, :integer
  end
end
