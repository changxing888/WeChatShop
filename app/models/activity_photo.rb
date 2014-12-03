class ActivityPhoto
  include Mongoid::Document
  include Mongoid::Timestamps

  mount_uploader :photo, PhotoUploader
  STATE = %w[pending approved rejected]
  

  field :photo,         type: String
  field :state,         type: String

  belongs_to :activity
  validates_presence_of :activity_id

  validate :state_available?, if: :state


  protected
  def state_available?
    errors.add(:state, "please select [pending approved rejected]") if !STATE.include?(state)
  end
end
