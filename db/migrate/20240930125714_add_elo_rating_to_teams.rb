class AddEloRatingToTeams < ActiveRecord::Migration[7.1]
  def change
    add_column :teams, :elo_rating, :integer, default: 1500
  end
end
