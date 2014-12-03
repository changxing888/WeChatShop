class Notification
  include Mongoid::Document
  include Mongoid::Timestamps

  field :dev_ids,               type: String
  field :location,              type: String
  field :message,               type: String
  
  validates_presence_of :message
  # def devices
  #     Device.in(id:dev_ids.split(',')) if dev_ids.present?
  # end

  def send_notifications
    return false if Rails.env.development?
    devices = Device.all
    devices.each do |dev|
      if dev.dev_id.present? and dev.push_state == true
        if dev.platform == Device::DEVICE_PLATFORM[0]    # in case platform is ios
          APNS.send_notification(dev.dev_id, alert:message, sound: 'default')
        else
          destination = [dev.dev_id]
          data = {:alert=>message}
          GCM.send_notification(destination,data)
        end
      end  
    end    
  end

  # handle_asynchronously :send_notifications, :priority => 20
end
