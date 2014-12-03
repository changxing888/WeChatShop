class UserActivityDateStatistic
  include Mongoid::Document
  include Mongoid::Timestamps
  STATISTICS = %w[browsed viewed saved shared added checked created]

  field :type,  type: String
  field :count, type: Integer, :default => 0
  
  belongs_to :user
  belongs_to :activity
  belongs_to :my_date

  scope :browsed_activities, ->{ where(:type => UserActivityDateStatistic::STATISTICS[0], :my_date_id.exists=>false) }
  scope :viewed_activities, ->{ where(:type => UserActivityDateStatistic::STATISTICS[1], :my_date_id.exists=>false) }
  scope :saved_activities, ->{ where(:type => UserActivityDateStatistic::STATISTICS[2], :my_date_id.exists=>false) }
  scope :shared_activities, ->{ where(:type => UserActivityDateStatistic::STATISTICS[3], :my_date_id.exists=>false) }
  scope :added_activities, ->{ where(:type => UserActivityDateStatistic::STATISTICS[4], :my_date_id.exists=>false) }
  scope :checked_activities, ->{ where(:type => UserActivityDateStatistic::STATISTICS[5], :my_date_id.exists=>false) }

  scope :browsed_dates, ->{ where(:type => UserActivityDateStatistic::STATISTICS[0], :my_date_id.exists=>true) }
  scope :viewed_dates, ->{ where(:type => UserActivityDateStatistic::STATISTICS[1], :my_date_id.exists=>true) }
  scope :saved_dates, ->{ where(:type => UserActivityDateStatistic::STATISTICS[2], :my_date_id.exists=>true) }
  scope :shared_dates, ->{ where(:type => UserActivityDateStatistic::STATISTICS[3], :my_date_id.exists=>true) }
  scope :created_dates, ->{ where(:type => UserActivityDateStatistic::STATISTICS[6], :my_date_id.exists=>true) }

  def name
    if self.activity.present?
      self.activity.name
    else
      self.my_date.name if self.my_date.present?
    end
  end

  def self.browsed_count(is_activity)
    if is_activity
      self.browsed_activities.sum(:count)
    else
      self.browsed_dates.sum(:count)
    end
  end
  def self.viewed_count(is_activity)
    if is_activity
      self.viewed_activities.sum(:count)
    else
      self.viewed_dates.sum(:count)
    end
  end
  def self.saved_count(is_activity)
    if is_activity
      self.saved_activities.sum(:count)
    else
      self.saved_dates.sum(:count)
    end
  end
  def self.shared_count(is_activity)
    if is_activity
      self.shared_activities.sum(:count)
    else
      self.shared_dates.sum(:count)
    end
  end
  def self.added_count(is_activity)
    if is_activity
      self.added_activities.sum(:count)
    else
      0
    end
  end
  def self.checked_count(is_activity)
    if is_activity
      self.checked_activities.sum(:count)
    else
      0
    end
  end


  def self.user_statistics(user,option, is_activity)
    if is_activity
      activities(user,option)
    else
      dates(user, option)
    end
  end


  def self.activities(user, option)
    my_dates = option.my_dates
    user_act_ids = []
    user.user_activity_date_statistics.each do |uads|
      user_act_ids = user_act_ids << uads.activity_id.to_s if uads.activity_id.present?
    end
    date_act_ids = []
    acts = MyDate.activities(my_dates)
    acts.each do |act|
      date_act_ids = date_act_ids << act.id.to_s
    end
    act_ids = user_act_ids & date_act_ids
    UserActivityDateStatistic.in(activity_id:act_ids)  
  end

  def self.dates(user, option)
    my_dates = option.my_dates
    user_date_ids = []
    user.user_activity_date_statistics.each do |uads|
      user_date_ids = user_date_ids << uads.my_date_id.to_s if uads.my_date_id.present?
    end
    all_date_ids = []
    my_dates.each do |date|
      all_date_ids = all_date_ids << date.id.to_s
    end
    date_ids = user_date_ids & all_date_ids
    UserActivityDateStatistic.in(my_date_id:date_ids)  
  end

end
