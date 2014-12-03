module Endpoints
  class ActivityPhotos < Grape::API

    resource :activity_photos do

      get :ping do
        { :ping => 'activity photos' }
      end

      
      # Upload photo
      # Parameters
      #   token: String *required
      #   activity_id: String *requried
      #   photo: Image *required
      # Returns
      # 	success: string
      post :upload_photo do
        user = User.find_by_token params[:token]
        if user.present?
          activity = Activity.where(id: params[:activity_id]).first
          if activity.nil?
            {:failure => "cannot find activity"}
          else
            photo = activity.activity_photos.build(photo:params[:photo],state:ActivityPhoto::STATE[0])
            if photo.save
              {success: 'uploaded successfully'}
            else
              {failure: photo.errors.messages}
            end
          end
        else
          {:failure => "cannot find user"}
        end
      end

      # Get photo list
      # Parameters
      #   token: String *required
      #   activity_id: String *requried
      #   photo: Image *required
      # Returns
      # 	success: JSON Object
      get :photos do

      end

    end
  end
end