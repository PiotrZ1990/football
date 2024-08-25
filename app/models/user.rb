class User < ApplicationRecord
  has_many :tickets, dependent: :destroy
  has_many :matches, through: :tickets

  # Devise modules
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
end
