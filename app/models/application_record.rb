class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
  self.inheritance_column = "_disabled" # free up the "type" column
end
