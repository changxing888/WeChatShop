class Food
  include Mongoid::Document

  mount_uploader    :default_logo,  FoodImageUploader
  mount_uploader    :selected_logo, FoodImageUploader

  field :order_id, type: Integer, :default => 0
  field :name, type: String
  field :active, type: Boolean
  field :img_ids, type: String
  validates_presence_of :name
  validates_numericality_of :order_id
  
  #has_many :logos, :as => :logoable,       dependent: :destroy
  
  def default_img_url
    if default_logo.url.nil?
      ''
    else
      if Rails.env.production?
        default_logo.url
      else
        "http://localhost:3000" + default_logo.url.gsub("#{Rails.root.to_s}/public/food/", "/food/")
      end
    end
  end
  
  def selected_img_url
    if selected_logo.url.nil?
      ''
    else
      if Rails.env.production?
        selected_logo.url
      else
        "http://localhost:3000" + selected_logo.url.gsub("#{Rails.root.to_s}/public/food/", "/food/")
      end
    end
  end

  # def self.last_order_id
  #   if Food.count > 0
  #     Food.all.order_by('order_id ASC').last.order_id.to_i
  #   else
  #     order_id = 0
  #   end
  # end
  # def default_img_url
  #   logo = default_img
  #   if logo.present?
  #     if Rails.env.development?
  #       return "http://192.168.0.55:3000" + logo.img_url
  #     else
  #       return logo.img_url
  #     end
  #   else
  #     return ''
  #   end
  # end
  # def selected_img_url
  #   logo = selected_img
  #   if logo.present?
  #     if Rails.env.development?
  #       return "http://192.168.0.55:3000" + logo.img_url
  #     else
  #       return logo.img_url
  #     end      
  #   else
  #     return ''
  #   end
  # end
  def logo_img_url
    self.default_img_url
  end
end
