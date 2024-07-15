class AddImageToLeagues < ActiveRecord::Migration[7.1]
  def change
    add_column :leagues, :image, :string
  end
end
