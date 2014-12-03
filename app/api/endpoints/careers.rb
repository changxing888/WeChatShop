module Endpoints
  class Careers < Grape::API

    resource :careers do

      # Test careers api
      # GET: /api/v1/careers/ping
      # RESULTS:
      #   'gwangming'
      get :ping do
        { :ping => 'gwangming' }
      end

      # Get Careers
      # GET: /api/v1/careers/careers
      # RESULTS:
      #    get careers
      get :careers do
        Career.where(active: true).order_by('order_id ASC')
      end

      # Get Career
      # GET: /api/v1/careers/career
      # PARAMS:
      #   token:         String *required
      # RESULTS:
      #   get career of user
      get :career do
        user = User.find_by_token params[:token]
        if user.nil?
          {:failure => 'not exists user'}
        else
          if user.user_career.nil?
            {:failure => 'not exists career'}
          else
            {:success => user.user_career.career.name}
          end
        end
      end
      
      # Set Career
      # POST: /api/v1/careers/set_career
      # PARAMS:
      #   token:         String *required
      # RESULTS:
      #   set career of user
      post :set_career do
        user = User.find_by_token params[:token]
        if user.nil?
          {:failure => 'not exists user'}
        else
          career = user.user_career.nil? ? user.build_user_career : user.user_career
          career.career_id = params[:career]
          if career.save
            GoogleAnalytics.new.event('career', 'set career', user.name, user.id)
            {:success => 'created'}
          else
            {:failure => 'failure not created'}
          end
        end
        
      end
    end

  end
end