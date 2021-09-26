class Account < ApplicationRecord
  include Rodauth::Rails.model

  has_one :profile, dependent: :destroy
  has_many :posts, dependent: :destroy
  has_many :identities, dependent: :destroy
end
