class Post < ApplicationRecord
  belongs_to :account, optional: true
end
