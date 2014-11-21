module Endpoints
  class Comments < Grape::API

    resource :comments do
      
      get :ping do
        {success:"Comments test"}
      end

      # Get comments by media id
      # GET: /api/v1/comments
      # parameters:
      #   token       String *required
      #   media_id    String *required
      
      get do
        media_id    = params[:media_id]
        user        = User.find_by_auth_token(params[:token])
        if user.present?
          media = Medium.find(media_id)
          if media.present?
            comments  = media.comments.map{|cm| cm.api_detail}
            likes     = media.likes
            {data:{comments:comments, like_count:likes.count},message:{type:'success',value:'get comments', code:TimeChatNet::Application::SUCCESS_QUERY}}
          else
            {data:[],message:{type:'error',value:'Can not find media', code:TimeChatNet::Application::MEDIA_NOT_FOUND}}
          end
        else
          {data:[],message:{type:'error',value:'Can not find this user', code:TimeChatNet::Application::ERROR_LOGIN}}
        end
      end


      # Add comment
      # POST: /api/v1/comments/add_comment
      # parameters:
      #   token       String *required
      #   media_id    String *required
      #   comment     String *required
      post :add_comment do
        media_id    = params[:media_id]
        comment     = params[:comment]
        user        = User.find_by_auth_token(params[:token])
        if user.present?
          media = Medium.find(media_id)
          if media.present?
            owner = media.user
            comment   = media.comments.create(comment:comment,user:user)
            
            comments  = media.comments.map{|cm| cm.api_detail}
            likes     = media.likes

            # owner.send_push_notification("You have received an comment from #{user.name}")
            {data:{comments:comments, like_count:likes.count},message:{type:'success',value:'Added new comment successfully', code:TimeChatNet::Application::SUCCESS_QUERY}}
          else
            {data:[],message:{type:'error',value:'Can not find media', code:TimeChatNet::Application::MEDIA_NOT_FOUND}}
          end
        else
          {data:[],message:{type:'error',value:'Can not find this user', code:TimeChatNet::Application::ERROR_LOGIN}}
        end
      end

      # Add audio comment
      # POST: /api/v1/comments/add_audio_comment
      # parameters:
      #   token             String *required
      #   media_id          String *required
      #   audio_comment     File *required
      post :add_audio_comment do
        media_id        = params[:media_id]
        audio_comment   = params[:audio_comment]
        user            = User.find_by_auth_token(params[:token])
        if user.present?
          media = Medium.find(media_id)
          if media.present?
            owner     = media.user
            comment   = media.comments.create(audio_comment:audio_comment, user:user)            
            comments  = media.comments.map{|cm| cm.api_detail}
            likes     = media.likes

            # owner.send_push_notification("You have received an comment from #{user.name}")
            {data:{comments:comments, like_count:likes.count},message:{type:'success',value:'Added new comment successfully', code:TimeChatNet::Application::SUCCESS_QUERY}}
          else
            {data:[],message:{type:'error',value:'Can not find media', code:TimeChatNet::Application::MEDIA_NOT_FOUND}}
          end
        else
          {data:[],message:{type:'error',value:'Can not find this user', code:TimeChatNet::Application::ERROR_LOGIN}}
        end
      end
      

    end #// resouce
  end
end
