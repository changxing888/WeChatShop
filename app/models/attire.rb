class Attire
  include Mongoid::Document

  mount_uploader    :default_logo,  AttireImageUploader
  mount_uploader    :selected_logo, AttireImageUploader
  mount_uploader    :thumb_logo,    AttireImageUploader

  field :order_id, type: Integer, :default => 0
  field :name, type: String
  field :active, type: Boolean
  field :img_ids, type: String
  #attr_accessible :order_id, :name, :color, :active

  field :default_logo,  type: String
  field :selected_logo, type: String
  field :thumb_logo,    type: String
  
  validates_presence_of :name
  validates_numericality_of :order_id
  #has_many :logos, :as => :logoable,       dependent: :destroy
  has_many :activities
  
  def default_img_url
    if default_logo.url.nil?
      ''
    else
      if Rails.env.production?
        default_logo.url
      else
        "http://localhost:3000" + default_logo.url.gsub("#{Rails.root.to_s}/public/attire/", "/attire/")
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
        "http://localhost:3000" + selected_logo.url.gsub("#{Rails.root.to_s}/public/attire/", "/attire/")
      end
    end
  end

  def thumb_img_url
    if thumb_logo.url.nil?
      ''
    else
      if Rails.env.production?
        thumb_logo.url
      else
        "http://localhost:3000" + thumb_logo.url.gsub("#{Rails.root.to_s}/public/attire/", "/attire/")
      end
    end
  end


  def self.last_order_id
    if Attire.count > 0
      Attire.all.order_by('order_id ASC').last.order_id.to_i
    else
      order_id = 0
    end
  end
  
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
  # def thumb_img_url
  #   logo = thumb_img
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
  def self.last_order_id
    if Attire.count > 0
      Attire.all.order_by('order_id ASC').last.order_id.to_i
    else
      order_id = 0
    end
  end
  
  def my_dates
    MyDate.where({:attire_ids => /.*#{self.id.to_s}*./})
  end  
end
