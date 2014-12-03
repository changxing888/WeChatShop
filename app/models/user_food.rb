class UserFood
  include Mongoid::Document
  belongs_to :user
  field :food,         :type => String
  
  #validates_presence_of :cost
  after_create :set_history
  after_update :update_history

  def foods
    if self.food.present?
      Food.in(id:self.food.split(","))
    else
      []
    end
  end
  
  private
    def set_history
      user_history = self.user.user_histories.build
      user_history.name = "Food Type Set -  #{self.foods.map{|f| f.name }.join(", ")}"
      user_history.type = self.class.name
      user_history.type_id = self.id
      user_history.save
    end
    def update_history
      user_history = self.user.user_histories.build
      user_history.name = "Food Type Update -  #{self.foods.map{|f| f.name }.join(", ")}"
      user_history.type = self.class.name
      user_history.type_id = self.id
      user_history.save
    end
end