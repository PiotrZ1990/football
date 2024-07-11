class CreateTeams < ActiveRecord::Migration[7.1]
  def change
    create_table :teams do |t|
      t.string :name
      t.string :location
      t.integer :year
      t.references :league, null: false, foreign_key: true

      t.timestamps
    end
  end
end
