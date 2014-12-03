class UserMeal
  include Mongoid::Document
  belongs_to :user
  field :meal,         :type => String
  
  #validates_presence_of :cost
  after_create :set_history
  after_update :update_history

  def meals
    Meal.in(id:self.meal.split(",")) if self.meal.present?
  end
  
  private
    def set_history
      user_history = self.user.user_histories.build
      user_history.name = "Meal Type Set -  #{self.meals.map{|m| m.name }.join(", ")}"
      user_history.type = self.class.name
      user_history.type_id = self.id
      user_history.save
    end
    def update_history
      user_history = self.user.user_histories.build
      user_history.name = "Meal Type Update -  #{self.meals.map{|m| m.name }.join(", ")}"
      user_history.type = self.class.name
      user_history.type_id = self.id
      user_history.save
    end
end