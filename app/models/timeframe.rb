class Timeframe
  include Mongoid::Document

  field :order_id, type: Integer, :default => 0
  field :name, type: String
  field :color, type: String
  field :active, type: Boolean

  #attr_accessible :order_id, :name, :color, :active
  validates_presence_of :name
  validates_numericality_of :order_id
  
  def time
    if self.name.to_i == 0
      24
    else
      self.name.to_i
    end
  end

  def self.last_order_id
    if Timeframe.count > 0
      Timeframe.all.order_by('order_id ASC').last.order_id.to_i
    else
      order_id = 0
    end
  end

  def my_dates
    MyDate.where({:timeframe_ids => /.*#{self.id.to_s}*./})
  end
end
