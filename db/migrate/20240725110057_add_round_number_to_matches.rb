class AddRoundNumberToMatches < ActiveRecord::Migration[7.1]
  def change
    add_column :matches, :round_number, :string
  end
end
