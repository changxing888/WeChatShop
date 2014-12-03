class Device
  include Mongoid::Document
  
  DEVICE_PLATFORM=%w[ios android]

  field :dev_id,          :type => String
  field :enabled,         :type => Boolean,   default: true
  field :platform,        :type => String,    default: 'ios'
  field :badge_count,     :type => Integer,   default: 0
  field :push_state,       :type => Boolean,   default: true
  
  belongs_to :user  

  validates_uniqueness_of :dev_id, :scope => :user_id

  scope :ios_devices, -> { where(:platform => Device::DEVICE_PLATFORM[0]) }
  scope :android_devices, -> { where(:platform => Device::DEVICE_PLATFORM[1]) }
  
end
