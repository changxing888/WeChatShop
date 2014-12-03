class CroppedLogo
  include Mongoid::Document
  include Mongoid::Timestamps

  mount_uploader :photo, PhotoUploader
  STATE = %w[pending approved rejected]
  
  attr_accessor :crop_x, :crop_y, :crop_w, :crop_h

  field :photo,         				type: String
  
  field :created_user_id,    		type: String
  
  field :approved_at,         	type: DateTime
  field :approved_user_id,    	type: String

	field :last_updated_user_id,	type: String
  
  belongs_to :logo
  belongs_to :created_by,       class_name: "User"
  belongs_to :approved_by,      class_name: "User"
  belongs_to :last_updated_by,  class_name: "User"

  validates_presence_of :logo_id, :photo
  
  def img_url
    if self.photo.url.nil?
      "none_image"
    else
      if Rails.env.production?
        self.photo.url(:thumb)
      else
        self.photo.url(:thumb).gsub("#{Rails.root.to_s}/public/cropped_logo/", "/cropped_logo/")
      end
    end
  end
  
  # def img_url
  #   if self.photo.url.nil?
  #     "none_image"
  #   else
  #     if Rails.env.production?
  #       self.photo.url
  #     else
  #       self.photo.url.gsub("#{Rails.root.to_s}/public/cropped_logo/", "/cropped_logo/")
  #     end
  #   end
  # end

  def file_size
    size = photo.thumb.file.size.to_i / 1024
    size.to_s + "KB"
  end

end
