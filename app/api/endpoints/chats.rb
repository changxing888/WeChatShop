module Endpoints
  class Chats < Grape::API

    resource :chats do

      get :ping  do
        {success: "wechatshop"}
      end

      # Get chat list
      # GET: /api/v1/chats
      # Parameters:
      #   token:      String *required
      get do
        user = User.find_by_token(token)
      end

      # Get chat list
      # POST: /api/v1/chats
      # Parameters:
      #   token:      String *required
      #   to:         String *required
      #   body:       String *required
      post do
        
      end

      
    end
  end
end
