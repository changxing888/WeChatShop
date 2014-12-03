module Endpoints
  class Incomes < Grape::API

    resource :incomes do

      # Test cost API
      # GET: /api/v1/incomes/ping
      # RESULTS:
      #   gwangming        
      get :ping do
        { :ping => 'gwangming' }
      end

      # Get incomes
      # GET: /api/v1/incomes/incomes
      # PARAMS:
      #   
      # RESULTS:
      #   get all incomes of backend
      get :incomes do
        Income.where(active: true).order_by('order_id ASC')
      end

      # Get income of user
      # GET: /api/v1/incomes/income
      # PARAMS:
      #   'token' String *required
      # RESULTS:
      #   get income of user      
      get :income do
        user = User.find_by_token params[:token]
        if user.nil?
          {:failure => 'not exists user'}
        else
          if user.user_income.nil?
            {:failure => 'not exists income'}
          else
            {:success => user.user_income.income.name}
          end
        end
      end
      
      # Set income of user
      # POST: /api/v1/incomes/income
      # PARAMS:
      #   'token'  String *required
      #   'income' String *required
      # RESULTS:
      #   set income of user  
      post :set_income do
        user = User.find_by_token params[:token]
        if user.nil?
          {:failure => 'not exists user'}
        else
          income = user.user_income.nil? ? user.build_user_income : user.user_income
          income.income_id = params[:income]
          if income.save
            {:success => 'created'}
          else
            {:failure => 'failure not created'}
          end
        end
        
      end
    end

  end
end