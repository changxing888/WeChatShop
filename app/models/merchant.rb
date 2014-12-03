class Merchant
  include Mongoid::Document
  include Mongoid::Timestamps
  LOCATION_SORT_TYPE = %w[order rand]
  REDIS_EXPIRE_TIME = 300                   # second

  field :name,            type: String
  field :email,           type: String
  field :first_name,      type: String
  field :last_name,       type: String
  field :yelp_id,         type: String
  field :yelp_name,       type: String  
   
  field :address1,        type: String
  field :address2,        type: String
  field :city,            type: String
  field :state,           type: String
  field :zip_code,        type: String
  field :country,         type: String

  field :phone,           type: String
  field :url,             type: String
  field :description,     type: String
  field :region_id,       type: Integer

  field :yelp_categories, type: String      #yelp categories string
  field :active,          type: Boolean,    default: true

  validates_presence_of :name, :yelp_id, :yelp_name
  validates_uniqueness_of :yelp_id
  
  has_one :geo_location,                    dependent: :destroy  
  has_many :activities,                     dependent: :destroy
  has_many :activity_hours,                 dependent: :destroy
  
  before_save :save_geolocation
  
  def address
    [self.address1, self.address2, self.city, "#{self.state} #{self.zip_code}"].reject(&:blank?).join(",")
  end
  def activity_categories
    self.activities.map{|act| act.categories_str}.join(", ")
  end

  def validate_address
    coordinates = Geocoder.coordinates(self.address)
    coordinates.present?
  end

  def distance(to_merchant)
    self.geo_location.distance(to_merchant.geo_location)
  end

  def open_days
    start_week_day = Date.today.beginning_of_week
    cur_date = Date.today
    past_day = cur_date - start_week_day
    open_dow = []    
    self.activity_hours.each do |ah|
      if ah.week > past_day
        open_dow << ah 
      end
    end
    open_days = open_dow.map{|w| (cur_date+w.week.day).strftime("%B %d - ")+w.hs_name}
  end

  def weeks
    self.activity_hours.map(&:week)
  end

  def open_dow_name                                               # Day of the Week
    self.activity_hours.map{|act_hour| act_hour.week_name}
  end
  def self.search params
    if params[:filter_category].present?
      cat = Category.find(params[:filter_category])
      activities = cat.activities
      m_ids = cat.activities.map{|act| act.merchant_id.to_s}
      merchants = Merchant.in(id:m_ids)
      if params[:filter_location].present?
        city = Location.find(params[:filter_location]).name        
        m_ids = m_ids & Merchant.any_of({city: city}).map{|m| m.id.to_s}
        merchants = Merchant.in(id:m_ids)
      else
        return merchants
      end
    elsif params[:filter_location].present?
      city = Location.find(params[:filter_location]).name
      merchants = Merchant.any_of({city: city})
    else
      merchants = Merchant.all
    end

    if params[:filter_state].present?
      state = params[:filter_state] == 'Active' ? true : false
      merchants.where(active:state)
    else
      merchants
    end
  end

  def self.locations
    Merchant.all.map(&:city).uniq
  end
  
  def self.find_by_yelp_id(id)
    Merchant.where(yelp_id:id).first
  end

  def self.find_by_location(location_name, near_by_value)
    loc_data = REDIS.get("#{location_name}_#{near_by_value}")
    if loc_data.present?
      m_ids = JSON.parse(loc_data)
    else
      #REDIS.flushall
      addr_coordinate = Geocoder.coordinates(location_name)
      locations = GeoLocation.near(addr_coordinate, near_by_value.to_i)
      if locations.present?
        merchants = locations.map(&:merchant).reject{|m| m.active==false}
        m_ids = merchants.map{|m| m.id.to_s}
      else
        m_ids = []
      end
      REDIS.set("#{location_name}_#{near_by_value}", m_ids.to_json)
      REDIS.expire("#{location_name}_#{near_by_value}", REDIS_EXPIRE_TIME)
    end
    return m_ids
  end

  def self.sort_from_activity_id(act_ids, m_ids)
    return [] if act_ids.nil? or m_ids.nil?
    lookup = {}    
    acts = Activity.in(id:act_ids)
    m_ids.each_with_index do |item, index|
      lookup[item] = index
    end

    acts.sort_by do |item|
      lookup.fetch(item.merchant_id.to_s)
    end
  end

  def self.sort(acts, m_ids, type=LOCATION_SORT_TYPE[0])
    lookup = {}
    
    m_ids = m_ids.sort{rand-0.5} if type == LOCATION_SORT_TYPE[1]
    
    m_ids.each_with_index do |item, index|
      lookup[item] = index
    end

    acts.sort_by do |item|
      lookup.fetch(item.merchant_id.to_s)
    end
  end


  def self.countries
    return [] if Merchant.count == 0
    map = %Q{
      function(){
        emit(this.country, {count: 1})
      }
    }
    reduce = %Q{
      function(key, values){
        var result = {count:0};
        values.forEach(function(value){
          result.count += value.count;
        });
        return result;
      }
    }
    results = Merchant.map_reduce(map,reduce).out(inline: true).to_a
    countries = []
    results.each do |r|
      countries << r["_id"]
    end
    return countries
  end
  
  def self.states(country)
    merchants = Merchant.where(country:country)
    return [] if merchants.count == 0
    map = %Q{
      function(){
        emit(this.state, {count: 1})
      }
    }
    reduce = %Q{
      function(key, values){
        var result = {count:0};
        values.forEach(function(value){
          result.count += value.count;
        });
        return result;
      }
    }
    results = merchants.map_reduce(map,reduce).out(inline: true).to_a
    countries = []
    results.each do |r|
      countries << r["_id"]
    end
    return countries
  end
  
  def self.cities(country, state)
    merchants = Merchant.where(country:country, state:state)
    return [] if merchants.count == 0
    map = %Q{
      function(){
        emit(this.city, {count: 1})
      }
    }
    reduce = %Q{
      function(key, values){
        var result = {count:0};
        values.forEach(function(value){
          result.count += value.count;
        });
        return result;
      }
    }
    results = merchants.map_reduce(map,reduce).out(inline: true).to_a
    countries = []
    results.each do |r|
      countries << r["_id"]
    end
    return countries
  end


  private
    def save_geolocation
      gl = self.geo_location.nil? ? self.build_geo_location : self.geo_location
      gl.update_attributes(address:[self.address1, self.address2, self.city, "#{self.state} #{self.zip_code}"].reject(&:blank?).join(","), zip_code:zip_code)
    end

end
