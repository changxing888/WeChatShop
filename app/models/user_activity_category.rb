class UserActivityCategory
  include Mongoid::Document
  belongs_to :user
  field :activity_category,              :type => String
  #validates_presence_of :activity_category

  after_create :set_history
  after_update :update_history

  def activity_categories
    if self.activity_category.present?
      Category.in(id:activity_category.delete(" ").split(",")).order_by("order_id ASC")
    else
      []
    end
  end
  
  
  private
    def set_history
      user_history = self.user.user_histories.build
      user_history.name = "Categories Set -  #{self.activity_categories.map{|c| c.display_name }.join(", ")}"
      user_history.type = self.class.name
      user_history.type_id = self.id
      user_history.save
    end
    def update_history
      user_history = self.user.user_histories.build
      user_history.name = "Category Update -  #{self.activity_categories.map{|c| c.display_name }.join(", ")}"
      user_history.type = self.class.name
      user_history.type_id = self.id
      user_history.save
    end
end
