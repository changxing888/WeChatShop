module Endpoints
  class Friends < Grape::API

    resource :friends do

      get :ping  do
        {success: TimeChatNet::Application::USER_UNREGISTERED}
      end



      # Get Friend List
      # GET: /api/v1/friends
      # parameters:
      #   token       String *required
      #   friend_id   String 
      get do
        user      = User.find_by_auth_token(params[:token])
        friend_id = params[:friend_id]
        if user.present?
          friend = User.where(id:friend_id).first
          if friend.present?
            friend_info = {id:friend.id.to_s, email:friend.email, avatar:friend.avatar_url, friend_status:user.is_block(friend), time_zone:friend.time_zone, username:friend.name}
            {data:friend_info, message:{type:'success',value:'Success query', code: TimeChatNet::Application::SUCCESS_QUERY}}
          else
            friends = user.friends_list.reject{|f| !user.is_friend(f)}
            friend_info = friends.map{|f| {id:f.id.to_s, email:f.email, avatar:f.avatar_url, debug:'Friend List', friend_status:user.is_block(f), time_zone:f.time_zone, username:f.name}}
            {data:friend_info, message:{type:'success',value:'Success query', code: TimeChatNet::Application::SUCCESS_QUERY}}
          end
        else
          {data:[],message:{type:'error',value:'Can not find this user', code: 0}}
        end
      end

      # Get Facebook Users
      # GET: /api/v1/friends/facebook_users
      # parameters:
      #   token       String *required
      get :facebook_users do
        user = User.find_by_auth_token(params[:token])
        if user.present?
          fb_users = User.where(social_type: User::SOCIAL_TYPES[1]).reject{|u| user.is_friend(u)}
          info = fb_users.map{|f| {id:f.id.to_s, email:f.email, debug:'Friend List', username:f.name, avatar:f.avatar_url}}
          {data:info, message:{type:'success',value:'Success query', code: TimeChatNet::Application::SUCCESS_QUERY}}
        else
          {data:[],message:{type:'error',value:'Can not find this user', code: 0}}
        end
      end

      # Get Google Users
      # GET: /api/v1/friends/google_users
      # parameters:
      #   token       String *required
      get :google_users do
        user = User.find_by_auth_token(params[:token])
        if user.present?
          gg_users = User.where(social_type: User::SOCIAL_TYPES[3]).reject{|u| user.is_friend(u)}
          info = gg_users.map{|f| {id:f.id.to_s, email:f.email, debug:'Friend List', username:f.name, avatar:f.avatar_url}}
          {data:info, message:{type:'success',value:'Success query', code: TimeChatNet::Application::SUCCESS_QUERY}}
        else
          {data:[],message:{type:'error',value:'Can not find this user', code: 0}}
        end
      end

      # Get Phonebook Users
      # GET: /api/v1/friends/phonebook_users
      # parameters:
      #   token       String *required
      #   emails      String *required
      get :phonebook_users do
        user = User.find_by_auth_token(params[:token])
        emails = params[:emails].split(",")
        
        if user.present?
          pb_users = User.in(email:emails).reject{|u| user.is_friend(u)}
          info = pb_users.map{|f| {id:f.id.to_s, email:f.email, debug:'Friend List', username:f.name, avatar:f.avatar_url}}
          {data:info, message:{type:'success',value:'Success query', code: TimeChatNet::Application::SUCCESS_QUERY}}
        else
          {data:[],message:{type:'error',value:'Can not find this user', code: 0}}
        end
      end      

      # Get Search Friends
      # GET: /api/v1/friends/search_friends
      # parameters:
      #   token               String *required
      #   emails              String *required  string that splitted by comma
      get :search_friends do
        user    = User.find_by_auth_token(params[:token])
        emails  = params[:email]
        if user.present?
          friends     = user.friends.in(email:emails.split(",")).reject{|f| !user.is_friend(f)}
          friend_info = friends.map{|f| {id:f.id.to_s, email:f.email, debug:'Friend List', friend_status:user.is_block(f), time_zone:f.time_zone, username:f.name}}
          {data:friend_info, message:{type:'success',value:'Success query', code: TimeChatNet::Application::SUCCESS_QUERY}}
        else
          {data:[], message:{type:'error',value:'Can not find this user', code: 0}}
        end
      end
      
      # Add Friend
      # POST: /api/v1/friends/add_friend
      # parameters:
      #   token               String *required
      #   email               String *required
      post :add_friend do
        email = params[:email]
        user  = User.find_by_auth_token(params[:token])
        if user.present?          
          friend = User.where(email:email).first
          if friend.present?
            if user.id == friend.id
              {data:[], message:{type:'error',value:"#{email} is your email", code: TimeChatNet::Application::USER_UNREGISTERED}}
            elsif user.is_friend(friend)
              {data:[], message:{type:'error',value:"#{email} is your friend now", code: TimeChatNet::Application::USER_UNREGISTERED}}
            elsif user.is_invited_friend(friend)
              {data:[], message:{type:'error',value:"#{email} is already invited", code: TimeChatNet::Application::USER_UNREGISTERED}}
            else
              user.add_friend(friend)
              {data:friend.friend_api_detail(user), message:{type:'success',value:'Added new friend', code: TimeChatNet::Application::SUCCESS_QUERY}}
            end
          else
            UserMailer.contact_user_email(email, user).deliver
            {data:[], message:{type:'error',value:"Sent invite email to #{email}", code: TimeChatNet::Application::USER_UNREGISTERED}}
          end
        else
          {data:[], message:{type:'error',value:'Can not find this user', code: TimeChatNet::Application::USER_UNREGISTERED}}
        end
      end

      # Add Friend
      # POST: /api/v1/friends/add_friend_by_username
      # parameters:
      #   token               String *required
      #   username            String *required
      post :add_friend_by_username do
        username  = params[:username].strip
        user      = User.find_by_auth_token(params[:token])
        if user.present?
          friend = User.where({:name=>/^#{username}$/i}).first
          p ">>>>>>#{username}>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
          p friend.id.to_s
          p ">>>>>>#{username}>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
          if friend.present?
            if user.id == friend.id
              {data:[], message:{type:'error',value:"#{username} is your username", code: TimeChatNet::Application::USER_UNREGISTERED}}
            elsif user.is_friend(friend)
              {data:[], message:{type:'error',value:"#{username} is your friend now", code: TimeChatNet::Application::USER_UNREGISTERED}}
            elsif user.is_invited_friend(friend)
              {data:[], message:{type:'error',value:"#{username} is already invited", code: TimeChatNet::Application::USER_UNREGISTERED}}
            else
              user.add_friend(friend)
              {data:friend.friend_api_detail(user), message:{type:'success',value:'Added new friend', code: TimeChatNet::Application::SUCCESS_QUERY}}
            end
          else
            {data:[], message:{type:'error',value:"#{username} dosen't exist", code: TimeChatNet::Application::USER_UNREGISTERED}}
          end
        else
          {data:[], message:{type:'error',value:'Can not find this user', code: TimeChatNet::Application::USER_UNREGISTERED}}
        end
      end

      # Add Friends
      # POST: /api/v1/friends/add_friends
      # parameters:
      #   token               String *required
      #   user_ids            String *required
      post :add_friends do
        user_ids  = params[:user_ids].split(",")
        user      = User.find_by_auth_token(params[:token])        
        if user.present?
          friends = User.in(id:user_ids)
          if friends.count > 0
            friends.each do |friend|
              if !user.is_friend(friend) and user.id != friend.id
                user.add_friend(friend)
              end
            end
            if friends.count > 1
              {data:[], message:{type:'success',value:'Added new friends', code: TimeChatNet::Application::SUCCESS_QUERY}}
            else
              {data:[], message:{type:'success',value:'Added new friend', code: TimeChatNet::Application::SUCCESS_QUERY}}
            end
          else
            {data:[], message:{type:'error',value:'Can not find friends', code: TimeChatNet::Application::USER_UNREGISTERED}}
          end          
        else
          {data:[], message:{type:'error',value:'Can not find this user', code: TimeChatNet::Application::USER_UNREGISTERED}}
        end
      end


      # Add Friends
      # POST: /api/v1/friends/add_friends_by_phone_book
      # parameters:
      #   token               String *required
      #   emails              String *required
      post :add_friends_by_phone_book do
        emails    = params[:emails].split(",")
        user      = User.find_by_auth_token(params[:token])
        if user.present?
          friends = []
          emails.each do |email|
            friend = User.where(email:email).first
            if friend.present?
              friends << friend
            else              
              UserMailer.contact_user_email(email, user).deliver
              UserTempNotification.create(email:email,user:user)              
            end            
          end
          
          if friends.count > 0
            friends.each do |friend|
              if !user.is_friend(friend) and user.id != friend.id
                user.add_friend(friend)
              end
            end
            if emails.count > 1
              {data:[], message:{type:'success',value:'Invited new friends', code: TimeChatNet::Application::SUCCESS_QUERY}}
            else
              {data:[], message:{type:'success',value:'Invited new friend', code: TimeChatNet::Application::SUCCESS_QUERY}}
            end
          else
            {data:[], message:{type:'success',value:'Invited new friends', code: TimeChatNet::Application::SUCCESS_QUERY}}
          end          
        else
          {data:[], message:{type:'error',value:'Can not find this user', code: TimeChatNet::Application::USER_UNREGISTERED}}
        end
      end


      # Accept Friend
      # POST: /api/v1/friends/accept_friend
      # parameters:
      #   token               String *required
      #   friend_id           String *required
      #   notification_id     String *required
      post :accept_friend do
        user            = User.find_by_auth_token(params[:token])
        friend_id       = params[:friend_id]
        notification_id = params[:notification_id]
        if user.present?
          friend = User.where(id:friend_id).first
          user.accept_friend(friend)
          notification = Notification.where(id:notification_id).first
          notification.read! if notification.present?
          {data:friend.friend_api_detail(user), message:{type:'success',value:'accept new friend', code:TimeChatNet::Application::SUCCESS_QUERY}}
        else
          {data:[], message:{type:'error',value:'Can not find this user', code: 0}}
        end
      end
      
      # Decline Friend
      # POST: /api/v1/friends/decline_friend
      # parameters:
      #   token               String *required
      #   friend_id           String *required
      #   notification_id     String *required
      post :decline_friend do
        user            = User.find_by_auth_token(params[:token])
        friend_id       = params[:friend_id]
        notification_id = params[:notification_id]
        if user.present?
          friend = User.where(id:friend_id).first          
          user.decline_friend(friend)          
          notification = Notification.where(id:notification_id).first          
          notification.read! if notification.present?
          {data:friend.friend_api_detail(user), message:{type:'success',value:'decline friend', code: TimeChatNet::Application::SUCCESS_QUERY}}
        else
          {data:[], message:{type:'error',value:'Can not find this user', code: 0}}
        end
      end

      # Ignore Friend
      # POST: /api/v1/friends/ignore_friend
      # parameters:
      #   token               String *required
      #   friend_id           String *required
      post :ignore_friend do
        user            = User.find_by_auth_token(params[:token])
        friend_id       = params[:friend_id]        
        if user.present?
          friend = User.find(friend_id)
          user.ignore_friend(friend)
          
          {data:friend.friend_api_detail(user), message:{type:'success',value:'ignore friend', code:TimeChatNet::Application::SUCCESS_QUERY}}
        else
          {data:[], message:{type:'error',value:'Can not find this user', code: 0}}
        end
      end

      # Remove Ignore Friend
      # POST: /api/v1/friends/remove_ignore_friend
      # parameters:
      #   token               String *required
      #   friend_id           String *required
      post :remove_ignore_friend do
        user            = User.find_by_auth_token(params[:token])
        friend_id       = params[:friend_id]        
        if user.present?
          friend = User.find(friend_id)
          user.remove_ignore_friend(friend)          
          {data:friend.friend_api_detail(user), message:{type:'success',value:'remove ignore friend', code:TimeChatNet::Application::SUCCESS_QUERY}}
        else
          {data:[], message:{type:'error',value:'Can not find this user', code: 0}}
        end
      end

      # Remove Friend
      # POST: /api/v1/friends/remove_friend
      # parameters:
      #   token               String *required
      #   friend_id           String *required
      post :remove_friend do
        user            = User.find_by_auth_token(params[:token])
        friend_id       = params[:friend_id]        
        if user.present?
          friend = User.find(friend_id)
          user.remove_friend(friend)          
          {data:friend.friend_api_detail(user), message:{type:'success',value:'remove friend', code:TimeChatNet::Application::SUCCESS_QUERY}}
        else
          {data:[], message:{type:'error',value:'Can not find this user', code: 0}}
        end
      end


    end
  end
end
