class Location
  include Mongoid::Document
  mount_uploader :logo, LocationLogoUploader

  field :order_id, type: Integer, :default => 0
  field :name, type: String
  field :logo, type: String
  field :active, type: Boolean

  validates_presence_of :name
  validates_numericality_of :order_id
  
  has_many :my_dates
  has_many :users
  has_one :sponsored_activity


  def self.activity_locations
    Location.in(name:Merchant.all.map(&:city).uniq).order_by("order_id ASC")
  end
  
  def self.last_order_id
    if Location.count > 0
      Location.all.order_by('order_id ASC').last.order_id.to_i
    else
      order_id = 0
    end
  end
  
  def logo_img_url
    if self.logo.url.nil?
      return ""
    else
      self.logo.url.gsub("#{Rails.root.to_s}/public/location/", "/location/")
    end
  end
end
