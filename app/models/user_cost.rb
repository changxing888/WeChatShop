class UserCost
  include Mongoid::Document
  belongs_to :user
  field :cost,         :type => String
  
  #validates_presence_of :cost
  before_save :remove_space
  after_create :set_history
  after_update :update_history
  def costs
    if self.cost.present?
      Cost.in(id:self.cost.split(",")) 
    else
      []
    end
  end
  
  private
    def set_history
      user_history = self.user.user_histories.build
      user_history.name = "Costs Set -  #{self.costs.map{|c| c.name }.join(", ")}"
      user_history.type = self.class.name
      user_history.type_id = self.id
      user_history.save
    end
    def update_history
      user_history = self.user.user_histories.build
      user_history.name = "Costs Update -  #{self.costs.map{|c| c.name }.join(", ")}"
      user_history.type = self.class.name
      user_history.type_id = self.id
      user_history.save
    end
    
    def remove_space
      self.cost = self.cost.delete(' ')
    end
end