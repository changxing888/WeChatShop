class ActivityHour
  include Mongoid::Document

  field :week,        type: Integer
  field :hour_start,  type: Float
  #field :min_start,   type: Integer, default: 0

  field :hour_end,    type: Float
  #field :min_end,     type: Integer, default: 0

  #attr_accessible :order_id, :name, :color, :active
  validates_presence_of :week, :hour_start, :hour_end
  belongs_to :merchant
  WEEKS = %w[Mon Tue Wed Thu Fri Sat Sun]
  HOURS = ['12:00 AM','01:00 AM','02:00 AM','03:00 AM','04:00 AM','05:00 AM','06:00 AM','07:00 AM','08:00 AM','09:00 AM','10:00 AM','11:00 AM','12:00 PM','01:00 PM','02:00 PM','03:00 PM','04:00 PM','05:00 PM','06:00 PM','07:00 PM','08:00 PM','09:00 PM','10:00 PM','11:00 PM']
  
  ACTIVITY_HOURS = ['12:00 am midnight','12:30 am','1:00 am','1:30 am','2:00 am','2:30 am','3:00 am','3:30 am','4:00 am','4:30 am','5:00 am','5:30 am','6:00 am','6:30 am','7:00 am','7:30 am','8:00 am','8:30 am','9:00 am','9:30 am','10:00 am','10:30 am','11:00 am','11:30 am','12:00 pm noon','12:30 pm','1:00 pm','1:30 pm','2:00 pm','2:30 pm','3:00 pm','3:30 pm','4:00 pm','4:30 pm','5:00 pm','5:30 pm','6:00 pm','6:30 pm','7:00 pm','7:30 pm','8:00 pm','8:30 pm','9:00 pm','9:30 pm','10:00 pm','10:30 pm','11:00 pm','11:30 pm',]

  def week_name
    ActivityHour::WEEKS[self.week]
  end

  def hs_name
    #ActivityHour::HOURS[self.hour_start]
    ACTIVITY_HOURS[(hour_start * 2).to_i]    
  end
  
  def he_name
    #ActivityHour::HOURS[self.hour_end]
    #hour_end.to_s + ":" + min_end.to_s
    ACTIVITY_HOURS[(hour_end * 2).to_i]
  end

  def date
    start_week_day = Date.today.beginning_of_week
    start_week_day + week.day
  end

  def self.hour_name(time)
    time = time.to_i
    if time < 12
      "#{time}AM"
    else
      "#{time-12}PM"
    end
  end
end
