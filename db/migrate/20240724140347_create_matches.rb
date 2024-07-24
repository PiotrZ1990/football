class CreateMatches < ActiveRecord::Migration[7.1]
  def change
    create_table :matches do |t|
      t.integer :league_id, null: false
      t.integer :season, null: false
      t.date :date, null: false
      t.integer :home_team_id, null: false
      t.integer :away_team_id, null: false
      t.integer :home_score, null: false
      t.integer :away_score, null: false
      t.string :result, null: false

      t.timestamps
    end

    add_index :matches, :league_id
    add_index :matches, :home_team_id
    add_index :matches, :away_team_id

    add_foreign_key :matches, :leagues
    add_foreign_key :matches, :teams, column: :home_team_id
    add_foreign_key :matches, :teams, column: :away_team_id
  end
end
