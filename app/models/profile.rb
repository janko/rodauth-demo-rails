class Profile < ApplicationRecord
  belongs_to :account, optional: true
end
