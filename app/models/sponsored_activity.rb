class SponsoredActivity
  include Mongoid::Document
  
  DEVICE_PLATFORM=%w[ios android]

  field :active,          :type => Boolean,   default: false
  # field :start_date,      :type => Date
  # field :end_date,        :type => Date
  field :start_index,     :type => Integer
  field :increment,       :type => Integer
  field :activity_ids,    :type => String  

  belongs_to :location

  after_create :update_activities
  after_update :update_activities

  validates_presence_of :start_index, :increment, :activity_ids, :location_id

  def all_activities
    cur_date = Time.now
    Activity.in(id:activity_ids.split(',')) if activity_ids.present?
  end

  def all_active_activities
    cur_date = Time.now
    Activity.in(id:activity_ids.split(',')).where({:st_date.lte=>cur_date, :ed_date.gt =>cur_date, :active =>true}) if activity_ids.present?
  end

  def activities_name
    all_activities.map(&:name).join(",") if all_activities.present?
  end

  protected
  def update_activities
    ids = activity_ids.split(",")
    activities = Activity.in(id:ids)
    activities.each do |act|
      act.update_attribute(:sponsored, true)
    end
  end
end
