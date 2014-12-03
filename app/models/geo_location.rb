class GeoLocation
  include Mongoid::Document
  include Geocoder::Model::Mongoid

  NEAR_BY_LIMIT = 15

  field :address, :type => String
  field :zip_code, :type => String
  field :coordinates, :type => Array

  geocoded_by :address
  #reverse_geocoded_by :coordinates
  
  after_validation :geocode          # auto-fetch coordinates
  #after_validation :reverse_geocode  # auto-fetch address

  belongs_to :merchant

  def distance(to_geo)
    self.distance_to(to_geo)
    #Geocoder::Calculations.distance_between(self.coordinates, to_geo.coordinates)
  end

  def self.get_address_by_zip_cod(zip_code)
    geo = GeoLocation.where(zip_code: zip_code).first
    geo.address
  end

  def self.get_activities_by_location(location)
    if location.length > 7               #geo_location is city name
      location = location.gsub(' ', '%20')
      address = GeoLocation.get_address(location)
    else                            #geo_location is zip_code
      zip_code = location
      geo = GeoLocation.where(zip_code: zip_code).first
      if geo.present?
        address = geo.address
      else
        address = GeoLocation.get_address(zip_code)
      end
    end
    locations = GeoLocation.near(address, 10)
    ids = locations.map{|geo| geo.merchant.id.to_s}
    m_ids = Merchant.in(id:ids).where(active:true).map{|m| m.id.to_s}
    geo_acts = Activity.in(merchant_id:m_ids)
  end
  
  def self.get_my_activities_by_location(user, location)
    if location.length > 7               #geo_location is city name
      location = location.gsub(' ', '%20')
      address = GeoLocation.get_address(location)
    else                            #geo_location is zip_code
      zip_code = location
      geo = GeoLocation.where(zip_code: zip_code).first
      if geo.present?
        address = geo.address
      else
        address = GeoLocation.get_address(zip_code)
      end
    end
    locations = GeoLocation.near(address, 10)
    ids = locations.map{|geo| geo.merchant.id.to_s}
    m_ids = Merchant.in(id:ids).where(active:true).map{|m| m.id.to_s}
    geo_acts = user.available_activities.in(merchant_id:m_ids)
  end

  def self.get_address(location)
    if location.length < 7
      uri = URI.parse("http://maps.googleapis.com/maps/api/geocode/json?address=#{location}&sensor=false")
      http = Net::HTTP.new(uri.host, uri.port)
       request= Net::HTTP::Get.new(uri.request_uri)
      response = http.request(request)
       data = JSON.parse(response.body)["results"].first
       geo = [data["geometry"]["location"]["lat"] ,addr = data["geometry"]["location"]["lng"]].join(",")
       addr = Geocoder.search(geo).first
     else
       addr = Geocoder.search(location).first
     end
     addr.address
  end
end