class UserCareer
  include Mongoid::Document
  belongs_to :user
  belongs_to :career

  validates_presence_of :career

  after_create :set_history
  after_update :set_history
  private
    def set_history
      user_history = self.user.user_histories.build
      user_history.name = "Career Set - #{self.career.name}"
      user_history.type = self.class.name
      user_history.type_id = self.id
      user_history.save
    end
    def update_history
      user_history = self.user.user_histories.build
      user_history.name = "Career Update - #{self.career.name}"
      user_history.type = self.class.name
      user_history.type_id = self.id
      user_history.save
    end
end
