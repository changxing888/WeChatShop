module Endpoints
  class Interests < Grape::API

    resource :interests do

      get :ping do
        { :ping => 'frank' }
      end

    end

  end
end