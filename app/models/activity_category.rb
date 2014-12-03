class ActivityCategory
  include Mongoid::Document
  belongs_to :activity
  belongs_to :category
end
