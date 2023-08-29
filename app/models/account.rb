class Account < ApplicationRecord
  include Rodauth::Model(RodauthMain)
  enum :status, unverified: 1, verified: 2, closed: 3

  has_one :profile, dependent: :destroy
  has_many :posts, dependent: :destroy
end
