class Meal
  include Mongoid::Document

  mount_uploader :image, MealImageUploader

  field :order_id,      type: Integer, :default => 0
  field :name,          type: String
  field :active,        type: Boolean

  field :image,         type: String

  validates_presence_of :name
  validates_numericality_of :order_id
  
  #has_one :logo, :as => :logoable,       dependent: :destroy
  
  def self.last_order_id
    if Meal.count > 0
      Meal.all.order_by('order_id ASC').last.order_id.to_i
    else
      order_id = 0
    end
  end
  
  def logo_img_url
    if image.url.nil?
      ""
    else
      if Rails.env.production?
        image.url
      else
        "http://localhost:3000" + image.url.gsub("#{Rails.root.to_s}/public/meal/", "/meal/")
      end
    end    
  end
end
