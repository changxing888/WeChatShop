class Income
  include Mongoid::Document
  mount_uploader :logo, IncomeLogoUploader

  field :order_id, type: Integer
  field :name, type: String
  field :logo, type: String
  field :active, type: Boolean

  validates_presence_of :name
  validates_numericality_of :order_id
  def self.last_order_id
    if Income.count > 0
      Income.all.order_by('order_id ASC').last.order_id.to_i
    else
      order_id = 0
    end
  end
  
  def logo_img_url
    if self.logo.url.nil?
      return ""
    else
      self.logo.url.gsub("#{Rails.root.to_s}/public/income/", "/income/")
    end
  end
end
