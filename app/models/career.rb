class Career
  include Mongoid::Document
  mount_uploader :logo, CareerLogoUploader

  field :order_id, type: Integer, :default => 0
  field :name, type: String
  field :logo, type: String
  field :active, type: Boolean

  validates_presence_of :name
  validates_numericality_of :order_id
  
  def self.last_order_id
    if Career.count > 0
      Career.all.order_by('order_id ASC').last.order_id.to_i
    else
      order_id = 0
    end
  end
  
  def logo_img_url
    if self.logo.url.nil?
      return ""
    else
      self.logo.url.gsub("#{Rails.root.to_s}/public/career/", "/career/")
    end
  end
end
