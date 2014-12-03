class Report
  include Mongoid::Document
  include Mongoid::Timestamps

  TYPE_OF_SEARCH = %w[Activities MyActivities MyDates SuggestedDates]

  field :location,             :type => String, :default => ""
  #field :location_type,        :type => String
  #field :geolocation,          :type => String
  field :interests,            :type => String
  field :datetype,             :type => String
  field :day,                  :type => String
  field :time,                 :type => String
  field :type_of_search,       :type => String
  
  field :results,              :type => String, :default => ""      # results IDS

  belongs_to :user

  def location_type
     if location.split(",").count == 4
      "Current Location"
     elsif location.split(",").count < 2
      "City"
     else
      "Full Address"
     end     
  end

  def geolocation
    coordinate = Geocoder.coordinates(location)
    "#{coordinate[0]} / #{coordinate[1]} /#{GeoLocation::NEAR_BY_LIMIT}" if coordinate.present?
  end

  def interests_str
    if interests.present?
      ids = interests.split(",")
      str=[]
      cats = Category.in(id:ids)
      cats.each do |cat|
        str << cat.name.join("->") if cat.present?
      end
      str.join(", ")
    else
      ''
    end
  end
end
