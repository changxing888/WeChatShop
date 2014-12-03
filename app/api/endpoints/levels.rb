module Endpoints
  class Levels < Grape::API

    resource :levels do

      # Test cost API
      # GET: /api/v1/levels/ping
      # RESULTS:
      #   gwangming   
      get :ping do
        { :ping => 'gwangming' }
      end

      # Get levels
      # GET: /api/v1/levels/levels
      # PARAMS:
      #   
      # RESULTS:
      #   get all levels of backend
      get :levels do
        all_levels = Level.where(:active => true).order_by('order_id ASC')
        levels = all_levels.map{|level| {id:level.id.to_s,name:level.name,default_img:level.default_img_url,selected_img:level.selected_img_url,thumb_img:level.thumb_img_url}}
        {success:levels}
      end

      # Get level of user
      # GET: /api/v1/levels/level
      # PARAMS:
      #   'token' String *required
      # RESULTS:
      #   get all levels of backend
      get :level do
        user = User.find_by_token params[:token]
        if user.nil?
          {:failure => 'not exists user'}
        else
          if user.user_level.nil?
            {:failure => 'not exists level'}
          else
            levels = user.user_level.levels.map{|level| {id:level.id.to_s,name:level.name,default_img:level.default_img_url,selected_img:level.selected_img_url,thumb_img:level.thumb_img_url}}
            {:success => levels}
          end
        end
      end
      
      # Set level of user
      # POST: /api/v1/levels/set_level
      # PARAMS:
      #   'token'  String *required
      #   'levels' String *required
      # RESULTS:
      #   get all levels of backend
      post :set_level do
        user = User.find_by_token params[:token]
        if user.nil?
          {:failure => 'not exists user'}
        else
          level = user.user_level.nil? ? user.build_user_level : user.user_level
          level.level = params[:levels].delete(" ")
          if level.save
            GoogleAnalytics.new.event('level', 'set level', user.name, user.id)
            {:success => 'created'}
          else
            {:failure => 'failure not created'}
          end
        end        
      end
    end

  end
end