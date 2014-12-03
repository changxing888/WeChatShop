class UserDateType
  include Mongoid::Document
  belongs_to :user
  field :date_type,     :type => String

  #validates_presence_of :date_type

  def date_types
    DateType.in(id:self.date_type.split(",")) if self.date_type.present?
  end
end
