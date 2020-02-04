class Post < ApplicationRecord
  belongs_to :account

  validates_presence_of :title, :body
end
