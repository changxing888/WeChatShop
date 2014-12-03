
class Contact
  include Mongoid::Document
  include Mongoid::Timestamps
  GENDER = %w[Male Female]  
  mount_uploader :avatar, AvatarUploader

  CONTACT_PAGE_LIMIT = 20
  ## Database authenticatable authentication_token
  
  field :email,         :type => String, :default => ""  
  
  field :nick_name,     :type => String
  field :first_name,    :type => String
  field :last_name,     :type => String
  field :gender,        :type => Boolean
  field :zip_code,      :type => String
  field :birth_date,    :type => Date
  field :phone,         :type => String  

  field :avatar,        :type => String
  
  field :contacted_date, :type => DateTime
  #field :foursquare,    :type => Boolean, :default => true
  
  field :facebook_user_name, :type => String
  field :twitter_user_name, :type => String

  field :cost_ids,      :type => String
  field :level_ids,     :type => String
  #field :food_ids,      :type => String
  field :drink_ids,     :type => String
  field :category_ids,  :type => String
  

  belongs_to :user
  
  #has_one :logo,                      as: :logoable #,    dependent: :destory
  has_many :my_dates
  validates_presence_of :user_id  
  
  after_create :create_history
  after_update :update_history
  
  validate :file_size

  def file_size
    return true if avatar.blank?
    if avatar.file.size.to_f/(1024*1024) > 0.3
      errors.add(:avatar, "You cannot upload a file greater than 0.3 MB, Please use image of 200 X 200")
    end
  end

  def name
    [self.first_name, self.last_name].reject(&:blank?).join(" ")
  end
  
  def age
    if self.birth_date.nil?
      return ''
    else
      now = Time.now.utc.to_date
      now.year -  self.birth_date.year - ((now.month > self.birth_date.month || (now.month == self.birth_date.month && now.day >= self.birth_date.day)) ? 0 : 1)
    end
  end
  
  def get_region    
    return self.zip_code if self.zip_code.length > 6    
    begin
      self.zip_code.to_region(city: true)
    rescue
      return ""
    end
  end
  
  def city
    self.get_region
  end
  
  def last_date
    if contacted_date.present?
      contacted_date.strftime("%m/%d/%Y")
    else
      'n/a'
    end
  end

  def last_visited
    user = User.where(email:self.email).first
    if user.present?
      user.last_sign_in_at
    else
      return ' '
    end
  end

  def dates
    user = User.where(email:self.email).first
    if user.present?
      return '3'
    else
      return ' '
    end
  end
  
  def visit_count
    user = User.where(email:self.email).first
    if user.present?
      user.sign_in_count
    else
      return ' '
    end
  end

  def is_datezr?
    user = User.where(email:self.email).first
    if user.present?
      return 'Yes'
    else
      return 'No'
    end
  end 

  def preference_activities
    acts = []
    return acts if self.category_ids.nil?    
    categories = self.category_ids.split(",")
    categories.each do |cat|
      acts = acts | cat.activities.in(cost_ids:self.costs_id).reject{|act| act.is_active? == false}
    end
    Activity.in(id:acts.map(&:id))
  end

  def categories
    if self.category_ids.present?
      Category.find(self.category_ids.split(","))
    else
      []
    end
  end
  def costs
    if self.cost_ids.present?
      Cost.in(id:self.cost_ids.split(","))
    else
      []
    end
  end

  def costs_id
    if self.costs.present?
      self.costs.map{|c| c.id.to_s}
    else
      []
    end
  end

  def levels
    if self.level_ids.present?
      Level.in(id:self.level_ids.split(","))
    else
      []
    end
  end

  # def foods
  #   if self.food_ids.present?
  #     Food.in(id:self.food_ids.split(","))
  #   else
  #     []
  #   end
  # end
  def phone_number
    if phone.present?
      phone
    else
      ""
    end
  end
  
  def logo_img
    if self.avatar.url.nil?
      ""
    else
      if Rails.env.production? 
        self.avatar.url
      else
        self.avatar.url
        # "http://192.168.0.55:3000" + self.avatar.url.gsub("#{Rails.root.to_s}/public/contact/", "/contact/")
      end
    end
  end
  def birth_day
    self.birth_date.strftime("%m/%d/%Y") if self.birth_date.present?
  end

  private
    def create_history
      #UserMailer.created_contact(self).deliver
      user_history = self.user.user_histories.build
      user_history.name = "Create contact -  #{self.name}"
      user_history.type = self.class.name
      user_history.type_id = self.id
      user_history.save
    end
    def update_history
      user_history = self.user.user_histories.build
      user_history.name = "Contact Update -  #{self.name}"
      user_history.type = self.class.name
      user_history.type_id = self.id
      user_history.save
    end
end
