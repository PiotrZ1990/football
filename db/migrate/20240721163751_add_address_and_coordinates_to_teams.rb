class AddAddressAndCoordinatesToTeams < ActiveRecord::Migration[7.1]
  def change
    add_column :teams, :address, :string
    add_column :teams, :city, :string
    add_column :teams, :lat, :decimal
    add_column :teams, :lng, :decimal
  end
end
