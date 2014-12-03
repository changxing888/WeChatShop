module Endpoints
  class Content < Grape::API

    resource :content do

      get :ping do
        { :ping => 'frank' }
      end

    end

  end
end