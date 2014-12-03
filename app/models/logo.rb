class Logo
  include Mongoid::Document
  include Mongoid::Timestamps
  mount_uploader :logo, LogoUploader
  STATE = %w[pending approved rejected]

  field :state,                   type: String
  field :logo,                    type: String
  field :state_change_at,         type: DateTime
  field :state_change_user_id,    type: BSON::ObjectId
  field :updated_user,            type: BSON::ObjectId
  field :updated_at,              type: DateTime
  field :reject_reason,           type: String, default: ""
  
  field :creator,             type: BSON::ObjectId
  field :created_at,          type: DateTime

  field :author,              type: String
  field :source_type,         type: String
  field :file_url,            type: String
  field :original_file_name,  type: String, default: ""
  field :download_date,       type: DateTime

  field :viewed_count,        type: Integer, default: 0
 
  field :order_ids,           type: String
  field :is_cover,            type: Boolean, default: false
  field :is_thumb,            type: Boolean

  belongs_to :logoable,       polymorphic: true
  belongs_to :user 

  has_one :cropped_logo
  #before_save :remove_previously_stored_logo_image_file, :on => :logo_changed
  validates :logo, :presence => true
  
  #validate :logo_size_validation
  #validate :validate_minimum_image_size
  
  scope :pending_photos, where(:state=>STATE[0])
  scope :approved_photos, where(:state=>STATE[1])
  scope :rejected_photos, where(:state=>STATE[2])

  def self.pending_count
    pending_photos.count
  end

  def self.approved_count
    approved_photos.count
  end

  def self.rejected_count
    rejected_photos.count
  end

  def state_changed_user
    User.find(state_change_user_id.to_s) if state_change_user_id.present?
  end

  def rejected_user
    User.find(state_change_user_id.to_s) if state_change_user_id.present?
  end

  def last_updated_user
    User.find(updated_user) if updated_user.present?
  end

  def file_size
    if logo.file.present?
      size = logo.file.size.to_i / 1024
      size.to_s + "KB"
    else
      "0 KB"
    end
  end

  def img_url
    logger = Logger.new('/Users/jflores/Desktop/log.txt')
    logger.debug(self.logo.url.to_s)
    if self.logo.url.nil?
      "none_image"
    else
      if Rails.env.production?
        self.logo.url
      else
        # self.logo.url.gsub("#{Rails.root.to_s}/public/logo/", "/logo/")
        file_sub_path = self.logo.url.gsub("#{Rails.root.to_s}/public/logo/", "/logo/")
        # Pathname.new(File.join(Rails.root.to_s, "public", "logo", "public", file_sub_path)).to_s
        Pathname.new(File.join(Rails.root.to_s, "public", "logo", file_sub_path)).to_s
      end
    end
  end

  def remove_previously_stored_logo_image_file
    logo = Logo.where(id:self.id).first
    logo.remove_logo! if logo.present?
  end

  def creator_email
    User.find(creator.to_s).email
  end

  #def thumb_img_url
  #  if self.logo.url.nil?
  #    "none_image"
  #  else
  #    if Rails.env.production?
  #      self.logo.url('thumb')
  #    else
  #      self.logo.url('thumb').gsub("#{Rails.root.to_s}/public/logo/", "/logo/")
  #    end
  #  end
  #end

  private 
  def logo_size_validation
    errors[:logo] << "should be less than 1MB" if logo.size > 1.megabytes
  end
  def validate_minimum_image_size
    if logo.present?
      path = Rails.env.production? ? logo.url : logo.path
      image = MiniMagick::Image.open(path)
      unless image[:width] == 1080 && image[:height] == 1920
        errors.add :logo, "Uploaded file is in the wrong size. The right size is Height: 1920px and Width: 1080px. Please try again."
      end
    else
      errors.add :logo, "Please select image"
    end
  end

end
