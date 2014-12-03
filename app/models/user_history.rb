class UserHistory
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :name,     type: String
  field :type,     type: String
  field :type_id, type:String
  #belongs_to :historyable, :polymorphic => true
  
  belongs_to :user
  def history
    obj = Kernel.const_get(self.type)
    obj.find(type_id)
  end
end
