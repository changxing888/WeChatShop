class UserActivity
  include Mongoid::Document
  belongs_to :user
  field :activity,         :type => String
  
  after_create :set_history
  after_update :update_history
  def activities
    Activity.in(id:self.activity.split(",")) if self.activity.present?
  end
  
  def activities_name
    if self.activities.present? and self.activities.count > 1
      self.activities.map{|act| act.name}.join(", ")
    elsif self.activities.present? and  self.activities.count == 1
      self.activities.first.name
    else
      ''
    end
  end

  private
    def set_history
      user_history = self.user.user_histories.build
      user_history.name = "Activity Set -  #{self.activities_name}"
      user_history.type = self.class.name
      user_history.type_id = self.id
      user_history.save
    end
    def update_history
      user_history = self.user.user_histories.build
      user_history.name = "Activity Update -  #{self.activities_name}"
      user_history.type = self.class.name
      user_history.type_id = self.id
      user_history.save
    end    
end