class Activity
  include Mongoid::Document
  include Mongoid::Timestamps
  #include Sunspot::Mongo
  ROTTEN_FILTER_OPTIONS = %w[box_office in_theaters opening upcoming new_releases]
  ACTIVITY_PAGE_LIMIT = 10
  CHECK_STATE = %w[pending checked]
  BEST_DAYS = %w[Monday Tuesday Wednesday Thursday Friday Saturday Sunday]
  ACTIVITY_STATE = %w[pending approved rejected]
  
  validates :name, uniqueness: true, presence: true

  before_save :save_categories
  
  field :name,            type: String
  
  field :phone,           type: String
  field :description,     type: String

  field :thumb_coordinates,     type: String
  field :cover_coordinates,     type: String
  
  field :rating,          type: String
  field :rating_img_url,  type: String

  field :expires,         type: Date
  field :discount,        type: String
  field :price,           type: Float,    default: 0
  field :is_free,         type: Boolean,  default: false      

  field :st_date,         type: DateTime
  field :ed_date,         type: DateTime
  field :ex_date,         type: DateTime

  field :browsed_count,   type: Integer,  default: 0
  field :viewed_count,    type: Integer,  default: 0
  field :saved_count,     type: Integer,  default: 0
  field :shared_count,    type: Integer,  default: 0
  field :added_count,     type: Integer,  default: 0
  field :checked_count,   type: Integer,  default: 0

  field :category_ids,    type: String
  field :cost_ids,        type: String
  
  field :income_ids,      type: String
  field :career_ids,      type: String
  field :level_ids,       type: String
  
  #field :meal_ids,        type: String
  #field :food_ids,        type: String
  field :timeframe_ids,   type: String
  field :parts_of_day_ids,type: String  
  field :best_days,       type: String #, default: "0,1,2,3,4,5,6"

  field :activity_public,  type: Boolean,  default: false
  field :activity_state,  type: String,   default: '0'
  field :reject_reason,   type: String

  field :active,          type: Boolean, default: true
  field :sponsored,       type: Boolean, default: false

  field :image_ids,       type: String
  field :ordered_ids,     type: String
  field :check_state,     type: String,   default: 'checked'

  field :approved_at,     type: DateTime
  field :approved_user_id,      type: String
  field :last_update_user_id,   type: String


  belongs_to :merchant
  belongs_to :attire
  belongs_to :user

  has_many :activity_categories,           dependent: :destroy
  has_many :logos, :as => :logoable,       dependent: :destroy
  
  
  validates_presence_of :category_ids, :level_ids, :attire_id, :timeframe_ids, :parts_of_day_ids
  
  scope :available_activities, where(active:true, activity_state:"1")
  scope :actived_activities, where(:active=>true)
  scope :unsponsored_activities, where(:sponsored=>false, active:true, activity_state:"1")
  scope :sponsored_activities, where(:sponsored=>true, active:true, activity_state:"1")



  def self.expired_activities
    Activity.any_of({:ed_date=>{:$lt=>Time.now}}, {:ex_date=>{:$lt=>Time.now}})
  end

  def self.unexpired_activities
    #acts = Activity.all.reject{|act| Activity.expired_activities.include? act}
    Activity.all #any_of({:ed_date=>{:$gte=>Time.now}, :ex_date=>{:$gte=>Time.now}}, {:ex_date.exists=>false, :ed_date.exists=>false})
  end

  def self.search(params, limit, is_pagenate = true)
    activities = Activity.all

    if params[:filter_category].present?
      cat = Category.find(params[:filter_category])
      activities = cat.activities
    end

    if params[:filter_location].present?
      city = Location.find(params[:filter_location]).name
      m_ids = Merchant.any_of({city: city}).map{|m| m.id.to_s}
      activities = activities.in(merchant_id:m_ids)
    end

    if params[:filter_state].present?
      state = params[:filter_state] == 'Active' ? true : false
      activities = activities.where(:active=>state)
    end

    if params[:filter_photo_state].present?
      if params[:filter_photo_state].downcase == Logo::STATE[0]
        activities = activities.pending_activities
      elsif params[:filter_photo_state].downcase == Logo::STATE[1]
        activities = activities.approved_activities
      elsif params[:filter_photo_state].downcase == Logo::STATE[1]
        activities = activities.reject_activities
      end
    end

    if params[:filter_status].present?
      activities = activities.where(:activity_state=>params[:filter_status])
    end
        
    if is_pagenate == true
      activities.paginate(page: params[:page], :per_page => limit) 
    else
      activities
    end
  end

  def is_active?
    return active
  end
  
  def get_activities_by_categories(cat_id)
    cat = Category.find(cat_id)
    cat.activities
  end
  
  def merchant_name
    self.merchant.name
  end
  
  def full_city
    [self.merchant.city, self.merchant.state].join(", ")
  end
  
  def city
    self.merchant.city
  end

  def location
    Location.where(name:self.city).first
  end

  def address
    self.merchant.address
  end
  
  def replace_cover_image(image_id)
    activity = self
    img = image_ids.split(",")
    img[0] = image_id
    activity.update_attribute(:image_ids, img.join(","))
  end

  def replace_thumb_image(image_id)
    activity = self
    img = image_ids.split(",")
    img[1] = image_id
    activity.update_attribute(:image_ids, img.join(","))
  end

  def cover_image
    first_img_file
  end

  # covered image
  def first_img_file
    return '' if image_ids.nil?
    logo = Logo.where(id:image_ids.split(",").first).first if image_ids.split(",").first.present?    
  end
  
  def first_img
    return '' if image_ids.nil?
    logo = Logo.where(id:image_ids.split(",").first).first if image_ids.split(",").first.present?    
    if logo.present?
      # if Rails.env.development?
      #   return "http://192.168.0.55:3000" + logo.img_url
      # else
        return logo.img_url
      # end      
    else
      url= ''
    end
  end
  
  # horizontal image
  def second_img
    if cover_image.present? && cover_image.cropped_logo.present?
      logo = cover_image.cropped_logo      
      if logo.present?
        # if Rails.env.development?
        #   return "http://192.168.0.55:3000" + logo.img_url
        # else
          return logo.img_url
        # end
      else
        url= ''
      end
    else
      return '' if image_ids.nil?
      logo = Logo.where(id:image_ids.split(",").second).first if image_ids.split(",").second.present?
      if logo.present?
        # if Rails.env.development?
        #   return "http://192.168.0.55:3000" + logo.img_url
        # else
          return logo.img_url
        # end
      else
        url= ''
      end
    end
  end
  
  def second_img_file
    if cover_image.present? && cover_image.cropped_logo.present?
      logo = cover_image.cropped_logo      
    else
      return '' if image_ids.nil?
      logo = Logo.where(id:image_ids.split(",").second).first if image_ids.split(",").second.present?
    end
  end

  # 
  def third_img
    return '' if image_ids.nil?
    logo = Logo.where(id:image_ids.split(",").third).first if image_ids.split(",").third.present?
    if logo.present?
      # if Rails.env.development?
      #   return "http://192.168.0.55:3000" + logo.img_url
      # else
        return logo.img_url
      # end
    else
      url = ''
    end
  end

  def facebook_share_img
    return '' if image_ids.nil?
    logo = Logo.find(image_ids.split(",").second) if image_ids.split(",").second.present?
    if logo.present?
      # if Rails.env.development?
      #   return "http://10.134.37.47:3000" + logo.thumb_img_url
      # else
        url = logo.img_url
        return url
      # end
    else
      url= ''
    end
  end

  def gallery_images(user)
    photos = []
    logos.where({:state.exists=>true}).each do |logo|
      if logo.creator.to_s == user.id.to_s
        photos << logo
      else
        photos << logo if logo.state == Logo::STATE[1]
      end
    end
    photos
  end

  def gallery_images_single(user, activity)
    photos = []

    if user.id == activity.user_id
      logos.where({:state.exists=>true}).each do |logo|
        if logo.creator.to_s == user.id.to_s
          photos << logo
        else
          photos << logo if logo.state == Logo::STATE[1]
        end
      end
    else
      logos.where({:state.exists=>true}).each do |logo|
        photos << logo if logo.state == Logo::STATE[1]
      end
    end
    photos
  end
  
  def categories
    Category.where(id:self.category_ids.split(","))    
  end

  def categories_str
    if self.category_ids.present?
      cat_obj = Category.in(id:self.category_ids.split(","))
      cat_obj.first.name.join("->") if cat_obj.first.present?
    end
  end

  def income_str
    obj = Income.where(id:self.income_ids.split(",").first).first
    return " " if obj.nil?    
    if self.income_ids.present?
      income_obj = Income.find(self.income_ids.split(",")).map {|income| income.name}
      income_obj.join(", ")
    else
      "Not setted"
    end
  end

  def career_str
    obj = Career.where(id:self.career_ids.split(",").first).first
    return " " if obj.nil?    
    if self.career_ids.present?
      career_obj = Career.find(self.career_ids.split(",")).map {|career| career.name}
      career_obj.join(", ")
    else
      "Not setted"
    end
  end

  def get_price
    return 'FREE' if is_free == true
    if self.price.present? and self.price.to_i > 0
      ActionController::Base.helpers.number_to_currency(self.price)
    else
      ''
    end
  end
  
  def is_free?
    return is_free    
  end

  def merchant_url
    merchant.url
  end

  def discount_info
    if discount.present?
      discount.to_s + "% Off"
    else
      "20% OFF"
    end
  end
  
  def timeframes_str
    timeframes = Timeframe.in(id:self.timeframe_ids.delete(" ").split(","))
    timeframes.map{|time| time.name}
  end

  def timeframes
    timeframes = Timeframe.in(id:self.timeframe_ids.delete(" ").split(","))
    timeframes.map{|time| time.time}
    #timeframes.last.time
  end
  
  def time_of_hour
    timeframes = Timeframe.in(id:self.timeframe_ids.delete(" ").split(","))    
    timeframes.last.present? ? timeframes.last.time : 0
  end

  def estimated_duration
    #timeframes.sum
    timeframes = Timeframe.in(id:self.timeframe_ids.delete(" ").split(","))
    timeframes.first.try(:name)
  end

  def hours
    hours_opt = {}
    hs_time = 0
    he_time = 0
    merchant.activity_hours.each_with_index do |ah_opt, index|
      hours_opt[index] = [ah_opt.week_name, ah_opt.hs_name.gsub(':00 ',''), ah_opt.he_name.gsub(':00 ','')]
      #if hs_time != ah_opt.hour_start or he_time != ah_opt.hour_end
      #  hours_opt[ah_opt.week_name] = [ah_opt.hs_name, ah_opt.he_name]
      #  hs_time = ah_opt.hour_start
      #  he_time = ah_opt.hour_end
      #end
    end
    return hours_opt.map{|item| "#{item[1][0]}:#{item[1][1]}-#{item[1][2]}"}
  end

  def parts_of_days
    p_days = PartsOfDay.in(id:self.parts_of_day_ids.delete(" ").split(","))
  end

  def first_open_day
    self.merchant.open_days.first
  end

  def weeks
    self.merchant.weeks
  end

  def cost_name
    if self.cost_ids.present?
      Cost.in(id:self.cost_ids.split(",")).map(&:name).join(",")
    else
      ""
    end
  end

  def cost_icon
    if self.cost_ids.present?
      ct = Cost.in(id:self.cost_ids.split(",")).first
      ct.thumb_img_url if ct.present?
    else
      ""
    end
  end

  def attire_name
    if self.attire.present?
      self.attire.name
    else
      ""
    end
  end
  
  def attire_icon
    if self.attire.present?
      self.attire.thumb_img_url
    else
      ""
    end
  end

  def level_name
    if self.level_ids.present?
      Level.in(id:self.level_ids.split(",")).map(&:name).join(",")
    else
      ""
    end
  end
  
  def level_icon
    if self.level_ids.present?
      lv = Level.in(id:self.level_ids.split(",")).first
      lv.thumb_img_url if lv.present?
    else
      ""
    end
  end

  def details(my_act_ids, liked_acts_ids)
    act = self
    {id:act.id.to_s,
      name:act.name,
      category:act.categories_str,
      venue:act.merchant_name,
      description:act.description,
      address:act.address,
      phone:act.merchant.phone,
      website:act.merchant.url,
      pricing:act.get_price,
      img_url1:act.first_img,
      img_url2:act.second_img,
      img_url3:act.third_img,
      like:liked_acts_ids.include?(act.id), 
      hours:act.hours, 
      discount:act.discount_info, 
      duration:act.estimated_duration, 
      attire:act.attire_name, 
      cost:act.cost_name,
      level:act.level_name, 
      city:act.full_city,
      user_name:act.user_name,
      avatar:act.user_avatar,
      best_days: act.best_days,
      user_activities_count: Activity.where(user_id: act.user_id).size,
      state: get_activity_state,
      act_author_avatar: get_act_author_avatar,
      liked_count: act.get_liked_count,
      first_name:act.user.try(:first_name).present? ? act.user.first_name : "Tatiana", 
      last_name:act.user.try(:last_name).present? ? act.user.last_name : "Hughes",
    }
  end

  def get_liked_count
    liked_count = 0
    UserActivity.all.each do |ua|
      liked_count += 1 if ua.activity.include?(self.id.to_s)
    end
    liked_count
  end

  def get_act_author_avatar
    if self.user.present?
      self.user.avatar.url
    else
      "nil"
    end
  end

  def get_act_public
    self.activity_public
  end
  
  def get_activity_state
    #if self.user.nil?
    #  ACTIVITY_STATE[1]
    #else
    #  activity_public==true ? ACTIVITY_STATE[act.activity_state.to_i] : 'private'
    #end

    # if activity_public == true
    #   state = activity_state.present? ? activity_state.to_i : 0
    #   ACTIVITY_STATE[state]
    # else
    #   'private'
    # end 

    state = activity_state.present? ? activity_state.to_i : 0
    ACTIVITY_STATE[state]

  end

  def pending_photos
    logos.pending_photos
  end

  def pending_count
    logos.pending_count
  end

  def approved_photos
    photos = []
    ordered_photos = []
    unordered_photos = []    
    
    if logos.approved_photos.present? 
      logos.approved_photos.each do |l|
        photos << l
      end
    end

    if ordered_ids.present?
      ordered_ids.split(",").each do |id|
        ordered_photos << Logo.find(id)
      end      
    end

    
    if ordered_photos.present?
      unordered_photos = photos - ordered_photos
      photos = ordered_photos + unordered_photos
    end    
    photos
  end

  def approved_count
    approved_photos.count
  end

  def rejected_photos
    logos.rejected_photos
  end

  def rejected_count
    logos.rejected_count
  end

  
  def self.average_distance(act_ids)
    distance = Activity.all_distance(act_ids)
    if act_ids.count > 1
      distance / (act_ids.length-1)
    else
      distance
    end
  end
  
  def self.all_distance(act_ids)
    distance = 0
    activities = Activity.in(id:act_ids)
    point = activities.first
    activities.each do |act|
      distance = distance + point.merchant.distance(act.merchant)
      point = act
    end
    return distance
  end

  def self.opened_day(act_ids)
    opened_day = []
    activities = Activity.in(id:act_ids)
    activities.each do |act|
      opened_day = opened_day | act.merchant.open_dow_name
    end
    opened_day.uniq
  end

  def self.duration(act_ids)
    duration = 0
    activities = Activity.in(id:act_ids)
    timeframes = activities.map{|act| act.time_of_hour.to_i}
    timeframes.sum
  end

  def self.expires(act_ids)
    activities = Activity.in(id:act_ids)
    expires = activities.map{|act| act.expires}.compact
    expires.min
  end

  def self.parts_of_days(act_ids)
    activities = Activity.in(id:act_ids)
    p_day_ids = activities.map{|act| act.parts_of_day_ids}.compact
    p_day_ids = p_day_ids.join(",").split(",").uniq
    PartsOfDay.in(id:p_day_ids)
  end

  def self.all_best_days(act_ids)
    best_days = []
    acts = Activity.in(id:act_ids)
    acts.each do |a|
      best_days = best_days | a.best_days.split(',') if a.best_days.present?
    end
    best_days
  end

  def self.browsed_count
    self.sum(:browsed_count)
  end
  def self.viewed_count
    self.sum(:viewed_count)
  end
  def self.saved_count
    self.sum(:saved_count)
  end
  def self.shared_count
    self.sum(:shared_count)
  end
  def self.added_count
    self.sum(:added_count)
  end
  def self.checked_count
    self.sum(:checked_count)
  end

  def self.count_of_browsed(act_ids)
    Activity.in(id:act_ids).browsed_count
  end

  def self.count_of_viewed(act_ids)
    Activity.in(id:act_ids).viewed_count
  end

  def self.count_of_saved(act_ids)
    Activity.in(id:act_ids).saved_count
  end

  def self.count_of_shared(act_ids)
    Activity.in(id:act_ids).shared_count
  end

  def self.count_of_added(act_ids)
    Activity.in(id:act_ids).added_count    
  end

  def self.count_of_checked(act_ids)
    Activity.in(id:act_ids).checked_count    
  end

  def self.set_browsed_count(user, activities)    
    activities.each do |act|
      act.update_attribute(:browsed_count,act.browsed_count.to_i + 1)
      #uads = user.user_activity_date_statistics.where(activity_id: act.id, type: UserActivityDateStatistic::STATISTICS[0]).first
      #if uads.present?
      #  uads.update_attribute(:count, uads.count.to_i + 1)      
      #else
      uads = user.user_activity_date_statistics.build(activity_id:act.id, type:UserActivityDateStatistic::STATISTICS[0], count: 1)
      uads.save
      #end
    end
  end

  def self.set_viewed_count(user, activity)
    activity.update_attribute(:viewed_count,activity.viewed_count.to_i+1)
    #uads = user.user_activity_date_statistics.where(activity_id: activity.id, type: UserActivityDateStatistic::STATISTICS[1]).first
    #if uads.present?
    #  uads.update_attribute(:count, uads.count.to_i + 1)
    #else
    uads = user.user_activity_date_statistics.build(activity_id:activity.id, type:UserActivityDateStatistic::STATISTICS[1], count: 1)
    uads.save
    #end
  end

  def self.set_saved_count(user, activities)
    activities.each do |act|
      act.update_attribute(:saved_count,act.saved_count.to_i+1)
      uads = user.user_activity_date_statistics.where(activity_id: act.id, type: UserActivityDateStatistic::STATISTICS[2]).first
      #if uads.present?
      #  uads.update_attribute(:count, uads.count.to_i + 1)
      #else
      uads = user.user_activity_date_statistics.build(activity_id:act.id, type:UserActivityDateStatistic::STATISTICS[2], count: 1)
      uads.save
      #end
    end
  end

  def self.set_shared_count(user, activity)
    activity.update_attribute(:shared_count,activity.shared_count.to_i+1)
    #uads = user.user_activity_date_statistics.where(activity_id: activity.id, type: UserActivityDateStatistic::STATISTICS[3]).first
    #if uads.present?
    #  uads.update_attribute(:count, uads.count.to_i + 1)
    #else
    uads = user.user_activity_date_statistics.build(activity_id:activity.id, type:UserActivityDateStatistic::STATISTICS[3], count: 1)
    uads.save
    #end
  end

  def self.set_added_count(user, activity)
    activity.update_attribute(:added_count,activity.added_count.to_i+1)
    #uads = user.user_activity_date_statistics.where(activity_id: activity.id, type: UserActivityDateStatistic::STATISTICS[4]).first
    #if uads.present?
    #  uads.update_attribute(:count, uads.count.to_i + 1)
    #else
    uads = user.user_activity_date_statistics.build(activity_id:activity.id, type:UserActivityDateStatistic::STATISTICS[4], count: 1)
    uads.save
    #end
  end

  def self.set_checked_count(user, activity)
    activity.update_attribute(:checked_count,activity.checked_count.to_i+1)
    #uads = user.user_activity_date_statistics.where(activity_id: activity.id, type: UserActivityDateStatistic::STATISTICS[5]).first
    #if uads.present?
    #  uads.update_attribute(:count, uads.count.to_i + 1)
    #else
    uads = user.user_activity_date_statistics.build(activity_id:activity.id, type:UserActivityDateStatistic::STATISTICS[5], count: 1)
    uads.save
    #end
  end
  

  #  for API
  def self.all_activities(cost_ids)
    m_ids = Merchant.where(active:true).map{|m| m.id.to_s}
    activities = Activity.in(merchant_id:m_ids, cost_ids:cost_ids).reject{|act| act.is_active? == false}
    acts = Activity.in(id:activities.map(&:id))
  end

  def self.activities_by_current_location(user, location)
    mine_acts       = user.preference_activities

    nearby_1_ids    = Merchant.find_by_location(location, 1)
    near_1_acts     = Activity.in(merchant_id:nearby_1_ids).sort{rand-0.5}
    near_1_acts     = near_1_acts & mine_acts
    
    nearby_3_ids    = Merchant.find_by_location(location, 3)
    nearby_3_ids    = nearby_3_ids - nearby_1_ids
    near_3_acts     = Activity.in(merchant_id:nearby_3_ids).sort{rand-0.5}
    near_3_acts     = near_3_acts & mine_acts

    nearby_5_ids    = Merchant.find_by_location(location, 5)
    nearby_5_ids    = nearby_5_ids - nearby_3_ids - nearby_1_ids
    near_5_acts     = Activity.in(merchant_id:nearby_5_ids).sort{rand-0.5}
    near_5_acts     = near_5_acts & mine_acts

    nearby_all_15_ids   = Merchant.find_by_location(location, 15)
    nearby_15_ids       = nearby_all_15_ids - nearby_5_ids - nearby_3_ids - nearby_1_ids
    near_15_acts        = Activity.in(merchant_id:nearby_15_ids).sort{rand-0.5}
    near_15_acts        = near_15_acts & mine_acts

    near_15_all_acts    = Activity.in(merchant_id:nearby_all_15_ids)
    near_15_all_acts    = Merchant.sort(near_15_all_acts, nearby_all_15_ids)

    all_near_acts   = near_1_acts | near_3_acts | near_5_acts | near_15_acts
    other_acts      = near_15_all_acts - all_near_acts
    all_acts        = all_near_acts | other_acts

    return all_acts
  end

  def self.not_touch_activities
    Activity.where(check_state:Activity::CHECK_STATE[0])
  end
  
  def self.pending_activities
    acts = self.all.reject{|act| act.pending_count < 1}
    Activity.in(id:acts.map(&:id))
  end

  def self.approved_activities
    acts = self.all.reject{|act| act.approved_count < 1}
    Activity.in(id:acts.map(&:id))
  end

  def self.reject_activities
    acts = self.all.reject{|act| act.rejected_count < 1}
    Activity.in(id:acts.map(&:id))
  end

  def user_name
    if user.present?
      user.name
    else
      'Tatiana'
    end
  end

  def user_email
    if user.present?
      user.email
    elsif
      'test@test.com'
    end
  end
  
  def user_avatar
    if user.present?
      user.logo_img
    else
      ''
    end
  end

  def get_user(email)
    usr = User.find_by(email: email.to_s)
    return usr
  end


  def approved_user
    User.find(approved_user_id) unless approved_user_id.nil?
  end
  def approved_user_name
    approved_user.present? ? approved_user.name : 'Tatiana'
  end

  def last_update_user
    User.find(last_update_user_id) unless last_update_user_id.nil?
  end
  def last_update_user_name
    last_update_user.present? ? last_update_user.name : 'Tatiana'
  end

  private
    def save_categories
      cat_ids = self.category_ids.split(",")
      self.activity_categories.destroy_all
      cat_ids.uniq.each do |cat_id|
        act_cat = self.activity_categories.build(category_id: cat_id)
        act_cat.save
      end
    end

end