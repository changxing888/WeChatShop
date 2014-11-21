module Endpoints
  class Notifications < Grape::API

    resource :notifications do      
      get :ping do
        {success: 'test notifications'}
      end      

      # Get notifications
      # GET: /api/v1/notifications
      # parameters:
      #   token               String *required      
      get do
        user = User.find_by_auth_token(params[:token])
        if user.present?
          notifications = user.notifications.order("created_at DESC")
          notif_info = notifications.map{|notif| notif.api_detail}
          {data:notif_info, message:{type:'success',value:'notifications', code: 7}}
        else
          {data:[], message:{type:'error',value:'Can not find this user', code: 0}}
        end
      end

      # Get notification count
      # GET: /api/v1/notification_count
      # parameters:
      #   token               String *required      
      get :notification_count do
        user = User.find_by_auth_token(params[:token])
        if user.present?
          notifications = user.unread_notifications
          {data:{count:notifications.count}, message:{type:'success',value:'notifications', code: 7}}
        else
          {data:[], message:{type:'error',value:'Can not find this user', code: 0}}
        end
      end

      # Delete notification
      # POST: /api/v1/notifications/delete
      # parameters:
      #   token               String *required
      #   notification_id     String *required
      post :delete do
        user            = User.find_by_auth_token(params[:token])
        notification_id = params[:notification_id]
        if user.present?
          notification  = Notification.find(notification_id)
          notification.destroy
          {data:[], message:{type:'success',value:'deleted notification', code: 7}}
        else
          {data:[], message:{type:'error',value:'Can not find this user', code: 0}}
        end
      end
      
      # Delete notification
      # POST: /api/v1/notifications/had_read_notification
      # parameters:
      #   token               String *required      
      post :had_read_notification do
        user    = User.find_by_auth_token(params[:token])        
        if user.present?
          notifications = user.unread_notifications          
          notifications.each do |notif|
            notif.update_attributes(is_read:true)
          end
          {data:[], message:{type:'success',value:'read notifications', code: 7}}
        else
          {data:[], message:{type:'error',value:'Can not find this user', code: 0}}
        end
      end

      # Remove all notification
      # POST: /api/v1/notifications/remove_all
      # parameters:
      #   token               String *required      
      post :remove_all do
        user    = User.find_by_auth_token(params[:token])        
        if user.present?
          notifications = user.notifications.destroy_all
          {data:[], message:{type:'success',value:'removed all notifications successfully', code: 7}}
        else
          {data:[], message:{type:'error',value:'Can not find this user', code: 0}}
        end
      end



    end #notifications
  end
end
