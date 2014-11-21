module Endpoints
  class Medias < Grape::API

    resource :medias do
      # test medias api
      get :ping do
        {success: "Media Endpoints"}
      end      
      # Get all media
      # GET: /api/v1/medias
      # parameters:
      #   token               String *required
      get do
        user = User.find_by_auth_token(params[:token])
        if user.present?
          medias = user.medias
          info    = medias.map{|m| {id:m.id.to_s, filename:m.media_url, thumb:m.thumb_url, type:m.media_type, user_time:user.time.strftime("%Y-%m-%d %H:%M:%S"), user_id:user.id.to_s,created_at:media.created_time(user.time_zone)}}
          {data:info,message:{type:'success',value:'get all medias', code:TimeChatNet::Application::SUCCESS_QUERY}}
        else
          {data:[],message:{type:'error',value:'Can not find this user', code:TimeChatNet::Application::ERROR_LOGIN}}
        end
      end

      # Get all shared media
      # GET: /api/v1/medias/shared_medias
      # parameters:
      #   token               String *required
      get :shared_medias do
        user = User.find_by_auth_token(params[:token])
        if user.present?
          medias =  Medium.shared_medias(user).map{|m| {id:m.id.to_s, media:m.media_url, owner_id:m.user.id.to_s}}
          {data:medias,message:{type:'success',value:'get all medias', code:TimeChatNet::Application::SUCCESS_QUERY}}
        else
          {data:[],message:{type:'error',value:'Can not find this user', code:TimeChatNet::Application::ERROR_LOGIN}}
        end
      end

      # Get media info by media id
      # GET: /api/v1/medias/media_info
      # parameters:
      #   token               String *required
      #   media_id            String *required
      get :media_info do
        user      = User.find_by_auth_token(params[:token])
        media_id  = params[:media_id]
        if user.present?
          media = Medium.find(media_id)          
          info = [{id:media.id.to_s, filename:media.media_url, thumb:media.thumb_url, type:media.media_type, user_time:user.time.strftime("%Y-%m-%d %H:%M:%S"), user_id:user.id.to_s,created_at:media.created_time(user.time_zone)}]
          {data:info,message:{type:'success',value:'get all medias', code:TimeChatNet::Application::SUCCESS_QUERY}}
        else
          {data:[],message:{type:'error',value:'Can not find this user', code:TimeChatNet::Application::ERROR_LOGIN}}
        end
      end

      # Get media for period
      # GET: /api/v1/medias/media_for_period
      # parameters:
      #   token               String *required
      #   hour                String *required
      get :media_for_period do
        user = User.find_by_auth_token(params[:token])        
        
        if user.present?
          if params[:hour].present?
            hour = params[:hour].to_i - user.time_zone.to_i
            medias  = user.medias.medias_by_time(hour)
          else
            medias  = user.medias
          end          
          info    = medias.map{|m| {id:m.id.to_s, filename:m.media_url, thumb:m.thumb_url, type:m.media_type, user_time:user.time.strftime("%Y-%m-%d %H:%M:%S"), user_id:user.id.to_s,created_at:m.created_at.strftime("%Y-%m-%d %H:%M:%S")}}
          {data:info,message:{type:'success',value:'get all medias', code:TimeChatNet::Application::SUCCESS_QUERY}}
        else
          {data:[],message:{type:'error',value:'Can not find this user', code:TimeChatNet::Application::ERROR_LOGIN}}
        end
      end

      # Get medias for friend
      # GET: /api/v1/medias/medias_for_friend
      # parameters:
      #   token               String *required
      #   friend_id           String *required
      get :medias_for_friend do
        user = User.find_by_auth_token(params[:token])
        friend = User.find(params[:friend_id])
        if user.present?
          timezone = friend.time_zone.to_i
          friend_time = Time.now + timezone.hour
          friend.clear_media
          
          st_date = DateTime.new(friend_time.year,friend_time.month,friend_time.day) - timezone.hour
          medias  = friend.medias.where(:created_at.gte => st_date).order("created_at ASC")
          info    = medias.map{|m| {id:m.id.to_s, filename:m.media_url, thumb:m.thumb_url, type:m.media_type, user_time:user.time.strftime("%Y-%m-%d %H:%M:%S"), user_id:user.id.to_s,created_at:m.created_time(user.time_zone)}}
          {data:info,message:{type:'success',value:'get all medias', code:TimeChatNet::Application::SUCCESS_QUERY}}
        else
          {data:[],message:{type:'error',value:'Can not find this user', code:TimeChatNet::Application::ERROR_LOGIN}}
        end
      end

      # Upload new media
      # POST: /api/v1/medias/upload
      # parameters:
      #   token               String *required
      #   media               Image Data
      #   media_type          String *required [photo, video]
      #   video_thumb         Image Data
      post :upload do
        user        = User.find_by_auth_token(params[:token])        
        media       = params[:media]
        video_thumb = params[:video_thumb]
        media_type  = params[:media_type]        
        if user.present?          
          if media_type == '1'
            media = user.medias.build(file:media, media_type:media_type)
          else
            media = user.medias.build(file:media, media_type:media_type, video_thumb:video_thumb)
          end
          if media.save
            {data:{id:media.id.to_s,filename:media.media_url},message:{type:'success',value:'success uploaded', code:TimeChatNet::Application::SUCCESS_UPLOADED}}
          else
            {data:media.errors.messages,message:{type:'error',value:'Can not create this media', code:TimeChatNet::Application::ERROR_LOGIN}}  
          end
          
        else
          {data:[],message:{type:'error',value:'Can not find this user', code:TimeChatNet::Application::ERROR_LOGIN}}
        end
      end

      # Update media
      # POST: /api/v1/medias/update
      # parameters:
      #   token               String *required
      #   media_id            String *required
      #   media               Image Data
      post :update do
        user        = User.find_by_auth_token(params[:token])
        media       = params[:media]
        media_id    = params[:media_id]
        if user.present?
          media = user.medias.find(media_id)
          media.update_attributes(file:media)
          {data:{id:media.id.to_s,media:media.media_url},message:{type:'success',value:'Update media', code:TimeChatNet::Application::SUCCESS_UPLOADED}}
        else
          {data:[],message:{type:'error',value:'Can not find this user', code:TimeChatNet::Application::ERROR_LOGIN}}
        end
      end

      # Share media
      # POST: /api/v1/medias/share
      # parameters:
      #   token               String *required
      #   media_id            String *required
      #   friend_id           String *required
      post :share do
        user        = User.find_by_auth_token(params[:token])
        media_id    = params[:media_id]
        friend      = User.find(params[:friend_id])
        if user.present?
          media = Medium.find(media_id)
          if media.present?
            media.share(friend)
            {data:{id:media.id.to_s,media:media.media_url},message:{type:'success',value:'Shared Media', code:TimeChatNet::Application::SUCCESS_UPLOADED}}
          else
            {data:[],message:{type:'error',value:'Can not find media', code:TimeChatNet::Application::MEDIA_NOT_FOUND}}  
          end
        else
          {data:[],message:{type:'error',value:'Can not find this user', code:TimeChatNet::Application::ERROR_LOGIN}}
        end
      end
      
      # Share medias
      # POST: /api/v1/medias/share_medias
      # parameters:
      #   token               String *required
      #   type                Integer
      #   media_id            String *required
      #   friend_ids          String *required
      post :share_medias do
        user          = User.find_by_auth_token(params[:token])        
        if user.present?
          friends     = User.in(id:params[:friend_ids].split(","))
          media       = Medium.find(params[:media_id])         
          if media.present?
            media.share_friends(user,friends)
            {data:{id:media.id.to_s,media:media.media_url},message:{type:'success',value:'Shared Media', code:TimeChatNet::Application::SUCCESS_UPLOADED}}
          else
            {data:[],message:{type:'error',value:'Can not find media', code:TimeChatNet::Application::MEDIA_NOT_FOUND}}  
          end
        else
          {data:[],message:{type:'error',value:'Can not find this user', code:TimeChatNet::Application::ERROR_LOGIN}}
        end
      end
      # Get like
      # GET: /api/v1/medias/like
      # parameters:
      #   token               String *required
      #   media_id            String *required
      get :like do
        user        = User.find_by_auth_token(params[:token])
        media_id    = params[:media_id]
        if user.present?
          media = Medium.find(media_id)
          if media.present?
            likes = media.likes
            {data:{count:likes.count},message:{type:'success',value:'added like', code:TimeChatNet::Application::SUCCESS_QUERY}}
          else
            {data:{count:0},message:{type:'error',value:'Can not find media', code:TimeChatNet::Application::MEDIA_NOT_FOUND}}  
          end
        else
          {data:[],message:{type:'error',value:'Can not find this user', code:TimeChatNet::Application::ERROR_LOGIN}}
        end
      end

      # Send like
      # POST: /api/v1/medias/like
      # parameters:
      #   token               String *required
      #   media_id            String *required
      post :like do
        user        = User.find_by_auth_token(params[:token])        
        media_id    = params[:media_id]        
        if user.present?
          media = Medium.find(media_id)
          if media.present?
            like  = media.likes.build(user:user)
            likes = media.likes
            if like.save
              {data:{count:likes.count},message:{type:'success',value:'added like', code:TimeChatNet::Application::SUCCESS_QUERY}}  
            else
              {data:{count:likes.count},message:{type:'error',value:like.errors.full_messages.first, code:TimeChatNet::Application::SUCCESS_QUERY}}
            end
            
          else
            {data:[],message:{type:'error',value:'Can not find media', code:TimeChatNet::Application::MEDIA_NOT_FOUND}}  
          end
        else
          {data:[],message:{type:'error',value:'Can not find this user', code:TimeChatNet::Application::ERROR_LOGIN}}
        end
      end

      # Get media info and post media
      # POST: /api/v1/medias/main_page_info
      # parameters:
      #   token               String *required
      #   media_id            String *required
      #   media_exist         Boolean
      #   media_type          String
      #   video_thumb         String
      #   media               String
      post :main_page_info do
        user        = User.find_by_auth_token(params[:token])        
        media_id    = params[:media_id]
        media_exist = params[:media_exist]
        media_type  = params[:media_type]
        video_thumb = params[:video_thumb]        
        media       = params[:media]
        if user.present?
          if media_exist == '1'
            if media_type == '1'
              media = user.medias.build(file:media, media_type:media_type)
            else
              media = user.medias.build(file:media, media_type:media_type, video_thumb:video_thumb)
            end            
            if media.save
              {data:{id:media.id.to_s,filename:media.media_url, created_at:media.created_time(user.time_zone), like_count:0, comment_count:0, notification_count:user.unread_notifications.count}, message:{type:'success',value:'success uploaded', code:TimeChatNet::Application::SUCCESS_UPLOADED}}
            else
              {data:media.errors.full_messages.first,message:{type:'error',value:'Can not create this media', code:TimeChatNet::Application::ERROR_LOGIN}}
            end
          else
            media = Medium.where(id:params[:media_id]).first
            likes = media.present? ? media.likes.count : 0
            comments = media.present? ? media.comments.count : 0
            filename = media.media_type == '0' ? media.thumb_url : media.media_url
            {data:{id:media.id.to_s,filename:filename, created_at:media.created_time(user.time_zone), like_count:likes, comment_count:comments, notification_count:user.unread_notifications.count}, message:{type:'success',value:'success query', code:TimeChatNet::Application::SUCCESS_QUERY}}
          end          
        else
          {data:[],message:{type:'error',value:'Can not find this user', code:TimeChatNet::Application::ERROR_LOGIN}}
        end
      end


    end #end medias
  end
end
