class PartsOfDay
  include Mongoid::Document

  field :order_id, type: Integer, :default => 0
  field :name, type: String
  field :active, type: Boolean

  #attr_accessible :order_id, :name, :color, :active
  validates_presence_of :name
  validates_numericality_of :order_id
  
  def self.last_order_id
    if PartsOfDay.count > 0
      PartsOfDay.all.order_by('order_id ASC').last.order_id.to_i
    else
      order_id = 0
    end
  end

  def my_dates
    MyDate.where({:parts_of_day_ids => /.*#{self.id.to_s}*./})
  end

end
