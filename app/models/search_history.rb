class SearchHistory
  include Mongoid::Document
  include Mongoid::Timestamps
  SEARCH_OPTIONS = %w[activity, date]
  SEARCH_TYPE = %w[location category day time]
  field :search_name,   type: String
  field :search_type,   type: String
  field :search_count,   type: Integer
  field :search_option,  type: String, default: "activity"

  scope :activity_locations, ->{ where(:search_type => SearchHistory::SEARCH_TYPE[0], search_option: SearchHistory::SEARCH_OPTIONS[0]).limit(5) }
  scope :activity_categories, ->{ where(:search_type => SearchHistory::SEARCH_TYPE[1], search_option: SearchHistory::SEARCH_OPTIONS[0]).limit(5) }
  scope :activity_days, ->{ where(:search_type => SearchHistory::SEARCH_TYPE[2], search_option: SearchHistory::SEARCH_OPTIONS[0]).limit(5) }

  scope :date_locations, ->{ where(:search_type => SearchHistory::SEARCH_TYPE[0], search_option: SearchHistory::SEARCH_OPTIONS[1]).limit(5) }
  scope :date_days, ->{ where(:search_type => SearchHistory::SEARCH_TYPE[2], search_option: SearchHistory::SEARCH_OPTIONS[1]).limit(5) }

  belongs_to :user
end
