class Account < ApplicationRecord
  has_one :profile
  has_many :posts
  has_many :identities
end
