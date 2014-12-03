module Endpoints
  class Partners < Grape::API

    resource :partners do

      get :ping do
        { :ping => 'frank' }
      end

    end

  end
end