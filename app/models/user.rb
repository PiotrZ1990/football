class User < ApplicationRecord
  has_many :tickets
  has_many :matches, through: :tickets

  # Devise modules
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
end
