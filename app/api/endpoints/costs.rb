module Endpoints
  class Costs < Grape::API

    resource :costs do

      # Test cost API
      # GET: /api/v1/costs/ping
      # RESULTS:
      #   gwangming  
      get :ping do
        { :ping => 'gwangming' }
      end

      # Get costs
      # GET: /api/v1/costs/costs
      # PARAMS:
      #   
      # RESULTS:
      #   get all costs of backend
      get :costs do
        all_costs = Cost.where(:active.exists=>true).order_by('order_id ASC')
        costs = all_costs.map{|cost| {id:cost.id.to_s,name:cost.name,default_img:cost.default_img_url,selected_img:cost.selected_img_url,thumb_img:cost.thumb_img_url}}
        {success:costs}
      end

      # Get cost of user
      # GET: /api/v1/costs/cost
      # PARAMS:
      #   'token' String *required
      # RESULTS:
      #   get cost of user      
      get :cost do
        user = User.find_by_token(params[:token])
        if user.nil?
          {:failure => 'not exists user'}
        else
          if user.user_cost.nil?
            {:failure => 'not setted cost'}
          else
            costs = user.user_cost.costs.map{|cost| {id:cost.id.to_s,name:cost.name,default_img:cost.default_img_url,selected_img:cost.selected_img_url,thumb_img:cost.thumb_img_url}}
            {:success => costs}
          end
        end
      end
      
      # Set cost of user
      # POST: /api/v1/costs/set_costs
      # PARAMS:
      #   'token' String *required
      #   'costs' String *required
      # RESULTS:
      #   set cost of user      
      post :set_costs do
        user = User.find_by_token(params[:token])
        if user.nil?
          {:failure => 'not exists user'}
        else
          cost = user.user_cost.nil? ? user.build_user_cost : user.user_cost
          cost.cost = params[:costs]
          if cost.save
            GoogleAnalytics.new.event('cost', 'set cost', user.name, user.id)
            {:success => 'created'}
          else
            {:failure => 'failure not created'}
          end
        end
        
      end
    end

  end
end