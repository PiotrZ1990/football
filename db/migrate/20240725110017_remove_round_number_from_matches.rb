class RemoveRoundNumberFromMatches < ActiveRecord::Migration[7.1]
  def change
    remove_column :matches, :round_number, :integer
  end
end
