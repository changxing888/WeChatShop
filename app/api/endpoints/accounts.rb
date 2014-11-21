module Endpoints
  class Accounts < Grape::API

    resource :accounts do
      # Forgot Password
      # POST: /api/v1/accounts/forgot_password
      # parameters:
      #   email:      String *required
      post :forgot_password do
        user = User.where(email:params[:email]).first
        if user.present?
          UserMailer.forgot_password(user).deliver          
          {data:[],message:{type:'success',value:'Please confirm your email address.', code: TimeChatNet::Application::SUCCESS_QUERY}}
        else
          {data:[],message:{type:'faild',value:'Cannot find this email', code: TimeChatNet::Application::ERROR_QUERY}}
        end
      end

      # Get Push Setting
      # GET: /api/v1/accounts/setting
      # parameters:
      #   token             String *required
      get :setting do
        user = User.find_by_auth_token(params[:token])
        if user.present?
          {data:{push_enable:user.push_enable,sound_enable:user.sound_enable,auto_accept_friend:user.auto_accept_friend,auto_notify_friend:user.auto_notify_friend, theme_type:user.theme_type},message:{type:'success',value:'account setting', code: TimeChatNet::Application::SUCCESS_QUERY}}
        else
          {data:[],message:{type:'error',value:'Can not find this user', code: TimeChatNet::Application::ERROR_LOGIN}}
        end
      end


      # Change profile
      # POST: /api/v1/accounts/change_profile
      # parameters:
      #   token             String *required
      #   old_password      String *required
      #   new_password      String *required
      #   user_name         String *required
      #   new_email         String *required
      #   avatar            String *required
      post :change_profile do

        old_password = params[:old_password]
        new_password = params[:new_password]
        
        user_name    = params[:user_name]
        new_email    = params[:new_email]

        avatar       = params[:avatar]

        is_changed   = true        
        user = User.find_by_auth_token(params[:token])
        
        if user.present?          
          if new_password.present?
            if user.valid_password?(old_password)
              user.password = new_password
              user.password_confirmation = new_password
              unless user.save
                is_changed = false
              end
            else
              is_changed = false
            end
          end

          if user_name.present?
            unless user.update_attribute(:name, user_name)
              is_changed = false
            end
          end

          if new_email.present?
            unless user.update_attribute(:email, new_email)
              is_changed = false
            end
          end

          if avatar.present?
            unless user.update_attribute(:avatar,avatar)
              is_changed = false
            end
          end

          if is_changed
            {data:[],message:{type:'success',value:'Changed profile successfully', code:TimeChatNet::Application::SUCCESS_QUERY}}
          else
            {data:[],message:{type:'faild',value:'Cannot Changed profile', code:TimeChatNet::Application::ERROR_QUERY}}
          end
        else
          {data:[],message:{type:'error',value:'Can not find this user', code:TimeChatNet::Application::ERROR_CHANGE_PASSWORD}}
        end
      end

      # Change Password
      # POST: /api/v1/accounts/change_password
      # parameters:
      #   token             String *required
      #   old_password      String *required
      #   new_password      String *required

      desc "Change Password"
      post :change_password do
        old_password = params[:old_password]
        new_password = params[:new_password]
        user = User.find_by_auth_token(params[:token])
        if user.present?
          if user.valid_password?(old_password)
            user.password = new_password
            user.password_confirmation = new_password
            if user.save
              {data:[],message:{type:'success',value:'Changed the password', code:TimeChatNet::Application::SUCCESS_CHANGE_PASSWORD}}
            else
              {data:user.errors.messages,message:{type:'error',value:'Can not changed the password', code:TimeChatNet::Application::SUCCESS_CHANGE_PASSWORD}}
            end
          else
            {data:[],message:{type:'error',value:user.errors.messages,code:TimeChatNet::Application::ERROR_CHANGE_PASSWORD}}
          end          
        else
          {data:[],message:{type:'error',value:'Can not find this user', code:TimeChatNet::Application::ERROR_CHANGE_PASSWORD}}
        end
      end

      # Change User name
      # POST: /api/v1/accounts/change_user_name
      # parameters:
      #   token             String *required
      #   user_name          String *required

      desc "Change user name"
      post :change_user_name do
        user_name = params[:username]
        user = User.find_by_auth_token(params[:token])
        if user.present?
          user.update_attribute(:name, user_name)
          {data:[],message:{type:'success',value:'Changed the user name', code: TimeChatNet::Application::SUCCESS_QUERY}}
        else
          {data:[],message:{type:'error',value:'Can not find this user', code: TimeChatNet::Application::ERROR_QUERY}}
        end
      end

      # Change email
      # POST: /api/v1/accounts/change_email
      # parameters:
      #   token             String *required
      #   new_email         String *required
      post :change_email do
        new_email = params[:new_email]
        user = User.find_by_auth_token(params[:token])
        if user.present?
          if user.update_attributes(email:new_email)
            {data:[],message:{type:'success',value:'Changed the new email', code: TimeChatNet::Application::SUCCESS_REGISTERED_PLEASE_CONFIRM_YOUR_EMAIL}}
          else
            {data:[],message:{type:'error',value:user.errors.messages, code: TimeChatNet::Application::ERROR_CHANGE_EMAIL}}
          end
        else
          {data:[],message:{type:'error',value:'Can not find this user', code: TimeChatNet::Application::ERROR_QUERY}}
        end
      end

      # Change avatar
      # POST: /api/v1/accounts/upload_avatar
      # parameters:
      #   token             String *required
      #   avatar            Image *required
      post :upload_avatar do
        avatar = params[:avatar]
        user = User.find_by_auth_token(params[:token])
        if user.present?
          if user.update_attributes(avatar:avatar)
            {data:[],message:{type:'success',value:'Changed the avatar', code: TimeChatNet::Application::SUCCESS_QUERY}}
          else
            {data:[],message:{type:'error',value:user.errors.messages, code: TimeChatNet::Application::ERROR_QUERY}}
          end
        else
          {data:[],message:{type:'error',value:'Can not find this user', code: TimeChatNet::Application::ERROR_LOGIN}}
        end
      end

      # Check sigined user
      # POST: /api/v1/accounts/check_token
      # parameters:
      #   token             String *required

      post :check_token do
        user = User.find_by_auth_token(params[:token])
        if user.present?
          #if (Time.now - user.last_sign_in_at) / 1.minute < 25
            user_info = {id:user.id.to_s, username:user.name,email:user.email,token:user.authentication_token,avatar:user.avatar.url}            
            setting   = {push_enable:user.push_enable,sound_enable:user.sound_enable,auto_accept_friend:user.auto_accept_friend,auto_notify_friend:user.auto_notify_friend, theme_type:user.theme_type,push_sound:user.push_sound}
            {data:{user_info:user_info, setting:setting},message:{type:'success',value:'login success', code: TimeChatNet::Application::SUCCESS_LOGIN}}
            
          #else
          #  render :json => {data:[],message:{type:'error',value:'sigin again', code: TimeChatNet::Application::ERROR_LOGIN}}
          #end          
        else
          {data:[],message:{type:'error',value:'Can not find this user', code: 0}}
        end
      end


      # Push setup
      # POST: /api/v1/accounts/push_setting
      # parameters:
      #   token             String *required
      #   push_enable       String 
      #   sound_enable      String
      post :push_setting do
        push_enable = params[:push_enable] == '1' ? true : false
        sound_enable = params[:sound_enable] == '1' ? true : false
        user = User.find_by_auth_token(params[:token])
        if user.present?
          if user.update_attributes(push_enable:push_enable, sound_enable:sound_enable)
            {data:[], message:{type:'success',value:'Push setting', code: TimeChatNet::Application::SUCCESS_QUERY}}
          else
            {data:[], message:{type:'error',value:'Can not push setting', code: TimeChatNet::Application::ERROR_QUERY}}  
          end
        else
          {data:[], message:{type:'error',value:'Can not find this user', code: TimeChatNet::Application::ERROR_LOGIN}}
        end
      end

      # Get Push Setting
      # GET: /api/v1/accounts/push_setting
      # parameters:
      #   token             String *required
      get :push_setting do
        user = User.find_by_auth_token(params[:token])
        if user.present?
          {data:{push_enable:user.push_enable,sound_enable:user.sound_enable},message:{type:'success',value:'Push setting', code: TimeChatNet::Application::SUCCESS_QUERY}}  
        else
          {data:[],message:{type:'error',value:'Can not find this user', code: TimeChatNet::Application::ERROR_LOGIN}}
        end
      end

      # Privacy setup
      # POST: /api/v1/accounts/privacy_setting
      # parameters:
      #   token                 String *required
      #   auto_accept_friend    Boolean 
      #   auto_notify_friend    Boolean
      post :privacy_setting do
        auto_accept_friend = params[:auto_accept_friend] == '1' ? true : false
        auto_notify_friend = params[:auto_notify_friend] == '1' ? true : false
        user = User.find_by_auth_token(params[:token])
        if user.present?
          if user.update_attributes(auto_accept_friend:auto_accept_friend, auto_notify_friend:auto_notify_friend)
            {data:[], message:{type:'success',value:'Privacy setting', code: TimeChatNet::Application::SUCCESS_QUERY}}
          else
            {data:[], message:{type:'error',value:'Can not privacy setting', code: TimeChatNet::Application::ERROR_QUERY}}  
          end
        else
          {data:[], message:{type:'error',value:'Can not find this user', code: TimeChatNet::Application::ERROR_LOGIN}}
        end
      end
     
      # Get Privacy Setting
      # GET: /api/v1/accounts/privacy_setting
      # parameters:
      #   token             String *required
      get :privacy_setting do
        user = User.find_by_auth_token(params[:token])
        if user.present?
          {data:{auto_accept_friend:user.auto_accept_friend,auto_notify_friend:user.auto_notify_friend},message:{type:'success',value:'Privacy setting', code: TimeChatNet::Application::SUCCESS_QUERY}}  
        else
          {data:[],message:{type:'error',value:'Can not find this user', code: TimeChatNet::Application::ERROR_LOGIN}}
        end
      end

      # Privacy setup
      # POST: /api/v1/accounts/theme_setting
      # parameters:
      #   token                 String *required
      #   theme_type            String
      
      post :theme_setting do
        theme_type = params[:theme_type]
        user = User.find_by_auth_token(params[:token])
        if user.present?
          if user.update_attributes(theme_type:theme_type)
            {data:[], message:{type:'success',value:'Theme type', code: TimeChatNet::Application::SUCCESS_QUERY}}
          else
            {data:[], message:{type:'error',value:'Can not theme type setting', code: TimeChatNet::Application::ERROR_QUERY}}  
          end
        else
          {data:[], message:{type:'error',value:'Can not find this user', code: TimeChatNet::Application::ERROR_LOGIN}}
        end
      end

      # Sound Setting
      # POST: /api/v1/accounts/sound_setting
      # parameters:
      #   token                 String *required
      #   push_sound            String
  
      post :sound_setting do
        push_sound = params[:push_sound]
        user = User.find_by_auth_token(params[:token])
        if user.present?
          if user.update_attributes(push_sound:push_sound)
            {data:[], message:{type:'success',value:'Push sound', code: TimeChatNet::Application::SUCCESS_QUERY}}
          else
            {data:[], message:{type:'error',value:'Can not set push sound', code: TimeChatNet::Application::ERROR_QUERY}}  
          end
        else
          {data:[], message:{type:'error',value:'Can not find this user', code: TimeChatNet::Application::ERROR_LOGIN}}
        end
      end
    end # end accounts
  end
end