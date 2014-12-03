class UserLevel
  include Mongoid::Document
  belongs_to :user
  field :level,         :type => String
  validates_presence_of :level

  after_create :set_history
  after_update :update_history
  def levels
    Level.in(id:self.level.split(",")) if self.level.present?
  end
  
  private
    def set_history
      user_history = self.user.user_histories.build
      user_history.name = "Level Set - #{self.levels.map{|level| level.name}.join(", ")}"
      user_history.type = self.class.name
      user_history.type_id = self.id
      user_history.save
    end
    def update_history
      user_history = self.user.user_histories.build
      user_history.name = "Level Set - #{self.levels.map{|level| level.name}.join(", ")}"
      user_history.type = self.class.name
      user_history.type_id = self.id
      user_history.save
    end
end