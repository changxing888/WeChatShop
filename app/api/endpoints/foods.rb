module Endpoints
  class Foods < Grape::API

    resource :foods do

      # Test cost API
      # GET: /api/v1/foods/ping
      # RESULTS:
      #   gwangming        
      get :ping do
        { :ping => 'frank' }
      end

      # Get foods
      # GET: /api/v1/costs/foods
      # PARAMS:
      #   
      # RESULTS:
      #   get all foods of backend
      get :foods do
        all_foods = Food.where(:active=>true).order_by('order_id ASC')
        foods = all_foods.map{|food| {id:food.id.to_s,name:food.name,default_img:food.default_img_url,selected_img:food.selected_img_url}}
      end

      # Get food of user
      # GET: /api/v1/costs/food
      # PARAMS:
      #   'token' String *required
      # RESULTS:
      #   get food of user
      get :food do
        user = User.find_by_token params[:token]
        if user.nil?
          {:failure => 'not exists user'}
        else
          if user.user_food.nil?
            {:failure => 'not setted food'}
          else
            foods = user.user_food.foods.map{|food| {id:food.id.to_s,name:food.name,default_img:food.default_img_url,selected_img:food.selected_img_url}}
            {:success => user.user_food.foods}
          end
        end
      end
      
      # Set food of user
      # POST: /api/v1/costs/set_foods
      # PARAMS:
      #   'token' String *required
      #   'foods' String *required
      # RESULTS:
      #   get food of user
      post :set_foods do
        user = User.find_by_token params[:token]
        if user.nil?
          {:failure => 'not exists user'}
        else
          food = user.user_food.nil? ? user.build_user_food : user.user_food
          food.food = params[:foods].delete(" ")
          if food.save
            GoogleAnalytics.new.event('food', 'set food', user.name, user.id)
            {:success => 'created'}
          else
            {:failure => 'failure not created'}
          end
        end
        
      end
    end

  end
end