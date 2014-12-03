class MyDate
  include Mongoid::Document
  include Mongoid::Timestamps
  
  SHARE_TYPE = %w[social community]
  DATE_STATES = %w[pending approved rejected n/a]
  DATE_PAGE_LIMIT = 20
  
  #field :name,          type: String
  field :activity_ids,      type: String
  field :anchor_id,         type: String
    
  field :date_duration,     type: Integer

  field :st_date,           type: DateTime
  field :ed_date,           type: DateTime

  field :user_ids,          type: String
  field :featured_id,       type: String
  
  field :category_ids,      type: String
  field :timeframe_ids,     type: String
  field :level_ids,         type: String

  field :parts_of_day_ids,  type: String
  field :active,            type: Boolean,        default: true
  field :private,           type: Boolean,        default: true

  field :browsed_count,     type: Integer,        default: 0
  field :viewed_count,      type: Integer,        default: 0
  field :saved_count,       type: Integer,        default: 0
  field :shared_count,      type: Integer,        default: 0

  
  field :last_updated_at,           type: DateTime
  field :last_updated_user_id,      type: String

  field :approved_at,               type: DateTime
  field :approved_user_id,          type: String
  
  field :rejected_at,               type: DateTime
  field :rejected_user_id,          type: String
  field :reject_reason,             type: String,   default: ''
  
  field :user_type,         type: String
  field :best_days,         type: String
  field :is_shared,         type: Boolean,        default: false
  field :date_state,        type: String,         default: '3'



  belongs_to :contact
  belongs_to :user
  
  belongs_to :date_type
  belongs_to :location

  #validates_presence_of :date_type_id, :dates_date, :st_time
  
  scope :featured, ->{ where(:user_id.exists=>false) }
  scope :featured_n_shared, ->{ any_of({:user_id.exists=>false},{:is_shared=>true}) }
  scope :user_generated, ->{ where(:user_id.exists=>true) }

  scope :user_personal_dates, where(:active => true, :private => true, :user_type => 'user')
  scope :suggested_dates, where(:active => true, :private => false, :user_type => 'admin')
  scope :user_shared_dates, where(:active => true, :private => false, :user_type => 'user')

  scope :all_users_suggested_dates, where(:active=> true, :private => false, :date_state => '1')  
  
  scope :users_suggested_dates, where(:active=> true, :private => false, :date_state => '0', :user_type => 'user')
  scope :users_rejected_dates, where(:active=> true, :private => false, :date_state => '2', :user_type => 'user')

  #before_save :set_user_type_and_best_days

  def self.search params
    all_dates = MyDate.all

    if params[:filter_option].present?
      if params[:filter_option] == "0"
        all_dates = MyDate.user_personal_dates
      elsif params[:filter_option] == "1"
        all_dates = MyDate.suggested_dates
      elsif params[:filter_option] == "2"
        all_dates = MyDate.user_shared_dates
      end
    end

    if params[:filter_location].present?
      all_dates = all_dates.in(location:params['filter_location'])
    end

    if params[:filter_date_type].present?
      all_dates = all_dates.where(date_type_id: params[:filter_date_type])
    end
    
    if params[:filter_status].present?
      status = params[:filter_status]=="Active" ? true : false
      all_dates = all_dates.where(active: status)
    end

    if params[:filter_state].present?
      all_dates = all_dates.where(date_state: params[:filter_state])
    end
    all_dates
  end

  def self.search_dates(date_option,option,duration,location)
    my_dates = date_option.my_dates
    dates = nil
    if option == 0
      if location.present?
        dates = my_dates.where(:created_at.gte => duration, :user_id.exists=>false, :location_id=>location)
      else
        dates = my_dates.where(:created_at.gte => duration, :user_id.exists=>false)
      end
    elsif option == 1
      if location.present?
        dates = my_dates.where(:created_at.gte => duration, :user_id.exists=>true, :location_id=>location)
      else
        dates = my_dates.where(:created_at.gte => duration, :user_id.exists=>true)
      end
    else option == 2
      if location.present?
        dates = my_dates.where(:created_at.gte => duration, :location_id=>location)
      else
        dates = my_dates.where(:created_at.gte => duration)
      end
    end
  end
  
  def last_updated_user    
    User.find(last_updated_user_id) if last_updated_user_id.present?
  end
  
  def approved_user
    User.find(approved_user_id)  if approved_user_id.present?
  end

  def rejected_user
    User.find(rejected_user_id)  if rejected_user_id.present?
  end

  def date_time    
    #if self.dates_date.present? and self.st_time.present? and self.duration.present?
    #  if self.st_time + duration >= 24
    #    ed_dt = self.dates_date + 1.day
    #    ed_time = (self.st_time+duration) - 24
    #    return self.dates_date.strftime("%b %d")+" #{ActivityHour::hour_name(self.st_time)} - " + ed_dt.strftime("%b %d")+" #{ActivityHour::hour_name(ed_time)}"
    #  else
    #    return self.dates_date.strftime("%b %d")+" #{ActivityHour::hour_name(self.st_time)} - #{ActivityHour::hour_name(self.st_time+self.duration)}"
    #  end
    #else
    #  ""
    #end    
    st_date.strftime("%m/%d/%Y %I:%p") + "-" + ed_date.strftime("%m/%d/%Y %I:%p") if st_date.present? and ed_date.present?
  end
  
  def anchor_activity    
    return [] if self.none_ordered_acts.nil?
    if self.none_ordered_acts.count == 1
      act = self.none_ordered_acts.first
    elsif
      if self.anchor_id.present?
        act = self.none_ordered_acts.where(id:anchor_id).first
        act = self.none_ordered_acts.first if act.blank?
      else
        act = self.none_ordered_acts.first
      end
    end
    return act
  end

  def dates_date
    dt = st_date.strftime("%m/%d/%Y") if st_date.present?
  end

  def st_time
    dt = st_date.strftime("%H").to_i if st_date.present?
  end

  def duration
    duration = (ed_date.to_time-st_date.to_time)/60/60
    duration.round(1)
  end

  def start_date_time
    return '' if self.activities.nil?
    if st_time.present?
      day = self.st_date.strftime("%b %d")
      hour = ActivityHour::hour_name(self.st_time)
      [day,hour]
    else
      if anchor_activity.present?
        day = anchor_activity.merchant.weeks
        hour =  anchor_activity.parts_of_days.map(&:name).join(", ")
        [day,hour]
      else
        ["",""]
      end
    end    
  end


  def date_location
    self.activities.present? ? self.activities.first.city : ""    
  end
  
  def is_active?
    return active
    # if active == true
    #   if activities.present?
    #     return activities.count > 0 ? true : false
    #   else
    #     false
    #   end
    # else
    #   return false
    # end
  end

  # def is_active?
  #   if active.present? and active == false
  #     false
  #   else
  #     if activities.count < 1
  #       false
  #     else
  #       true
  #     end
  #   end
  # end

  def activities
    if self.activity_ids.present?
      act_obj = []
      ids = self.activity_ids.delete(" ").split(",")
      ids.each do |id|
        act = Activity.where(id:id).first
        act_obj << act if act.present? and act.is_active? == true
      end
      act_obj
    end
  end

  def all_activities
    if self.activity_ids.present?
      act_obj = []
      ids = self.activity_ids.delete(" ").split(",")
      ids.each do |id|
        act = Activity.where(id:id).first
        act_obj << act if act.present?
      end
      act_obj
    end
  end

  def none_ordered_acts
    if self.activity_ids.present?
      Activity.in(id:self.activity_ids.delete(" ").split(","))
    end
  end

  def price
    if self.activities.present?
      price = self.activities.map{|act| act.price}.compact.sum
      ActionController::Base.helpers.number_to_currency(price)
    else
      ActionController::Base.helpers.number_to_currency(0)
    end
  end
  
  def activities_str
    self.activities.map{|act| act.name}.join(", ") if self.activities.present?
  end
    
  def is_featured?
    self.user.nil?
  end

  def name
    if self.activities.present?
      names = self.activities.map{|act| act.name}
      names.join(", ")
    else
      ""
    end
  end

  def activity_names
    if self.activities.present?
      names = self.activities.map{|act| act.name}
      names.join(",")
    else
      ""
    end
  end

  def activity_locations
    if self.activities.present?
      locations = self.activities.map{|act| act.location.try(:name)}
      locations.join(",")
    else
      ""
    end
  end

  def contact_name
    if self.contact.present?
      self.contact.name
    else
      ''
    end
  end
  
  def contact_age
    if self.contact.present?
      self.contact.age
    else
      ''
    end
  end
  def contact_city
    if self.contact.present?
      self.contact.city
    else
      ''
    end
  end
  
  def contact_id
    if self.contact.present?
      self.contact.id.to_s
    else
      ''
    end
  end

  def contact_last_date
    if self.contact.present?
      self.contact.last_date
    else
      ''
    end
  end

  def contact_img
    if self.contact.present?
      self.contact.logo_img
    else
      ''
    end
  end

  def date_type_name
    if self.date_type.present?
      self.date_type.name
    else
      ''
    end
  end
  
  def date_type_id
    if self.date_type.present?
      self.date_type.id.to_s
    else
      ''
    end
  end

  def img    
    return '' if self.none_ordered_acts.nil?
    return self.none_ordered_acts.first.second_img if self.none_ordered_acts.count == 1
    if self.none_ordered_acts.present?
      if self.anchor_id.present?
        act = self.none_ordered_acts.where(id:anchor_id)
        act = act.first.nil? ? self.none_ordered_acts.first : act.first
      else
        act = self.none_ordered_acts.first
      end     
      act.second_img
    else
      ""
    end
  end

  def date
    self.dates_date
  end
  def category
    self.none_ordered_acts.present? ? self.none_ordered_acts.first.categories_str : ''
  end

  def detail
    dt = self
    {
      date_type:dt.date_type_name,
      id:dt.id.to_s,
      name:dt.name,
      contact:dt.contact_name, 
      img:dt.img, 
      price:dt.price, 
      city:dt.date_location, 
      date_time:dt.date_time, 
      category:dt.category, 
      activity_names:dt.activity_names, 
      activity_locations:dt.activity_locations, 
      state:dt.active,
      status:dt.date_state,
      is_private:dt.private,
      avatar: dt.user.present? ? dt.user.logo_img : '',
      anchor_id:dt.anchor_activity.present? ? dt.anchor_activity.id.to_s : ''
    }
  end

  def details(user)
    dt = self
    MyDate.set_viewed_count(user, dt)
    
    my_act_ids  = user.activities.present? ? user.activities.map{|act| act.id} : []
    activities = []
    if dt.activity_ids.present?
      ids = dt.activity_ids.delete(" ").split(",")
      acts = []
      ids.each do |id|
        act = Activity.find(id)
        acts << act unless act.merchant.active == false
      end
      activities = acts.map{|act|{id:act.id.to_s,name:act.name,category:act.categories_str,price:act.get_price,img_url:act.second_img,himg_url:act.second_img, description:{day:act.first_open_day.present? ? act.first_open_day.split("-").first.strip : '',hour: act.first_open_day.present? ? act.first_open_day.split("-").second.strip : '',city:act.full_city,contact:dt.contact_name, venue:act.merchant_name, is_anchor:act.id.to_s==self.anchor_id, details:act.details(my_act_ids)}}}
    end
    dt_s = st_date.present? ? st_date.strftime("%m/%d/%Y,%I:%M %p") : ''
    dt_e = ed_date.present? ? ed_date.strftime("%m/%d/%Y,%I:%M %p") : ''
    
    {
      id:dt.id.to_s, 
      name:dt.name, 
      st_date:dt_s,
      ed_date:dt_e,
      date_type_id:dt.date_type_id,
      date_type:dt.date_type_name, 
      contact_id:dt.contact_id,
      contact_name:dt.contact_name, 
      contact_description:[dt.contact_age,dt.contact_city].join(", "), 
      last_date:dt.contact_last_date, 
      contact_img:dt.contact_img,
      activities:activities, 
      state:dt.active,
      status:dt.date_state,
      is_private:dt.private,
      avatar: dt.user.present? ? dt.user.logo_img : '',      
      contact_phone:dt.contact.present? ? dt.contact.phone_number : ''
    }
  end

  def add_user(user_id)
    return false if self.user.present?
    date = self
    if self.user_id.nil?
      user_ids = []
      if date.user_ids.nil?
        user_ids << user_id
      else
        user_ids = user_ids | self.user_ids.split(",")
      end
      date.update_attribute(:user_ids,user_ids.join(","))
      MyDate.set_saved_count(User.find(user_id),date)
    end
  end

  def get_date_state
    if self.user.present?
      if is_shared
        DATE_STATES[1].capitalize
      else
        DATE_STATES[date_state.to_i].capitalize
      end
    else
      DATE_STATES[date_state.to_i].capitalize
    end
  end

  def self.activities(dates)
    act_ids = []
    dates.each do |dt|
      act_ids = act_ids | dt.activity_ids.split(",") if dt.activity_ids.present?
    end
    act_obj = Activity.in(id:act_ids)
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

  def self.set_browsed_count(user, dates)
    dates.reject{|dt| dt.name.blank?}.each do |date|
      date.update_attribute(:browsed_count, date.browsed_count.to_i + 1)
      #uads = user.user_activity_date_statistics.where(my_date_id:date.id, type:UserActivityDateStatistic::STATISTICS[0]).first
      #if uads.present?
      #  uads.update_attribute(:count, uads.count.to_i + 1)      
      #else
      uads = user.user_activity_date_statistics.build(my_date_id:date.id, type:UserActivityDateStatistic::STATISTICS[0], count: 1)
      uads.save
      #end
    end
  end

  def self.set_viewed_count(user,date)
    return if date.name.blank? 
    date.update_attribute(:viewed_count, date.viewed_count.to_i+1)
    #uads = user.user_activity_date_statistics.where(my_date_id:date.id, type:UserActivityDateStatistic::STATISTICS[1]).first
    #if uads.present?
    #  uads.update_attribute(:count, uads.count.to_i + 1)
    #else
    uads = user.user_activity_date_statistics.build(my_date_id:date.id, type:UserActivityDateStatistic::STATISTICS[1], count: 1)
    uads.save
    #end
  end

  def self.set_saved_count(user, date)
    return if date.name.blank? 
    date.update_attribute(:saved_count,date.saved_count.to_i+1)
    #uads = user.user_activity_date_statistics.where(my_date_id:date.id, type:UserActivityDateStatistic::STATISTICS[2]).first
    #if uads.present?
    #  uads.update_attribute(:count, uads.count.to_i + 1)
    #else
    uads = user.user_activity_date_statistics.build(my_date_id:date.id, type:UserActivityDateStatistic::STATISTICS[2], count: 1)
    uads.save
    #end
  end

  def self.set_shared_count(user, date, type)
    return if date.name.blank?
    if type == SHARE_TYPE[1] 
      #date.update_attributes(shared_count:date.shared_count.to_i+1, is_shared:true)
      date.update_attributes(date_state:DATE_STATES[0])
    else
      date.update_attributes(shared_count:date.shared_count.to_i+1, is_shared:false)
    end
    #uads = user.user_activity_date_statistics.where(my_date_id: date.id, type: UserActivityDateStatistic::STATISTICS[3]).first
    #if uads.present?
    #  uads.update_attribute(:count, uads.count.to_i + 1)
    #else
    uads = user.user_activity_date_statistics.build(my_date_id:date.id, type:UserActivityDateStatistic::STATISTICS[3], count: 1)
    uads.save
    #end
  end

  def self.set_created_count(user, date)
    uads = user.user_activity_date_statistics.build(my_date_id:date.id, type:UserActivityDateStatistic::STATISTICS[6], count: 1)
    uads.save
  end

  private
    def set_user_type_and_best_days
      self.uset_type = self.user.type
      self.best_days = Activity.all_best_days(self.activity_ids.split(',')) if self.activity_ids.present?
    end

end
