class DateType
  include Mongoid::Document
  mount_uploader    :logo, DateTypeImageUploader

  field :order_id,  type: Integer, :default => 0
  field :name,      type: String
  field :active,    type: Boolean

  field :logo,      type: String
  #has_one :logo, :as => :logoable, dependent: :destroy

  has_many :my_dates

  validates_presence_of :name
  validates_numericality_of :order_id
  
  def logo_img_url
    if logo.url.nil?
      ""
    else
      if Rails.env.production?
        logo.url
      else
        "http://localhost:3000" + logo.url.gsub("#{Rails.root.to_s}/public/date_type/", "/date_type/")
      end
    end
  end

  def self.last_order_id
    if DateType.count > 0
      DateType.all.order_by('order_id ASC').last.order_id.to_i
    else
      order_id = 0
    end
  end
end
