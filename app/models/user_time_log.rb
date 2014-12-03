class UserTimeLog
  include Mongoid::Document  
  field :st_time,   type: DateTime
  field :ed_time,    type: DateTime
  
  belongs_to :user

  def duration
    end_time = ed_time.nil? ? st_time+0.2.hours : ed_time
    differ = (end_time.to_time - st_time.to_time)/60/60
    differ.round(5)
  end
end
