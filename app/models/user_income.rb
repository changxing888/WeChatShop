class UserIncome
  include Mongoid::Document
  belongs_to :user
  belongs_to :income

  validates_presence_of :income

  after_create :set_history
  after_update :update_history
  private
    def set_history
      user_history = self.user.user_histories.build
      user_history.name = "Income Set - #{self.income.name}"
      user_history.type = self.class.name
      user_history.type_id = self.id
      user_history.save
    end
    def update_history
      user_history = self.user.user_histories.build
      user_history.name = "Income Update - #{self.income.name}"
      user_history.type = self.class.name
      user_history.type_id = self.id
      user_history.save
    end
end