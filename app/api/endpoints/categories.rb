module Endpoints
  class Categories < Grape::API

    resource :categories do

      # Test API of categories
      # GET: /api/v1/categories/ping
      # RESULTS:
      #   'gwangming'
      get :ping do
        { :ping => 'gwangming' }
      end

      # Get categories
      # GET: /api/v1/categories/categories
      # PARAMS:
      #   category_id:         String *required
      # RESULTS:
      #   get categories of category_id
      get :categories do
        user = User.find_by_token params[:token]        
        if user.nil?
          if params[:category_id].nil?
            root_categories = Category.root_categories
            categories = root_categories.map{|cat| {id:cat.id.to_s,name:cat.display_name,img:cat.logo_img_url,selected:false}}
            {:success => categories}
          else
            root = Category.find(params[:category_id])
            categories = root.sub_categories.map{|cat| {id:cat.id.to_s,name:cat.display_name,img:cat.logo_img_url,selected:false}}
            {:success =>categories }
          end
        else
          GoogleAnalytics.new.page('/api/v1/categories/categories', 'get categories', user.id)
          if params[:category_id].nil?
            root_categories = Category.root_categories
            categories = root_categories.map{|cat| {id:cat.id.to_s,name:cat.display_name,img:cat.logo_img_url,selected:cat.selected?(user)}}
            {:success => categories}
          else
            root = Category.find(params[:category_id])
            categories = root.sub_categories.map{|cat| {id:cat.id.to_s,name:cat.display_name,img:cat.logo_img_url,selected:cat.selected?(user)}}
            {:success => categories}
          end
        end
      end
      
      # Get Category
      # GET: /api/v1/categories/category
      # PARAMS:
      #   token:         String *required
      # RESULTS:
      #   get categories of user
      get :category do
        user = User.find_by_token params[:token]
        if user.nil?
          {:failure => 'not exists user'}
        else
          if user.user_activity_category.nil?
            {:failure => 'not exists categories'}
          else
            cats = user.user_activity_category.activity_categories
            user_cats = cats.map{|cat| {id:cat.id.to_s,name:cat.display_name,img:cat.logo_img_url}}
            GoogleAnalytics.new.page('/api/v1/categories/category', 'get category details', user.id)
            {:success => user_cats }
          end
        end
      end

      # Set Category
      # POST: /api/v1/categories/set_categories
      # PARAMS:
      #   token:                    String *required
      #   selected_category_ids:    String *required
      #   unselected_category_ids:  String *required
      # RESULTS:
      #   set categories of user      
      post :set_categories do
        user = User.find_by_token params[:token]        
        if user.nil?
          {:failure => 'not exists user'}
        else
          category = user.user_activity_category.nil? ? user.build_user_activity_category : user.user_activity_category
          cur_categories = []
          
          cur_categories = category.activity_category.split(",") if category.activity_category.present?
          params[:unselected_category_ids].delete(" ").split(",").each do |del_cat|
            del_sub_cat = Category.find(del_cat).sub_categories.map{|scat| scat.id.to_s}
            cur_categories.delete(del_cat)
            cur_categories = cur_categories - del_sub_cat
          end

          categories = cur_categories | params[:selected_category_ids].delete(" ").split(",")

          category.activity_category = categories.join(",")
          
          if category.save
            GoogleAnalytics.new.event('category', 'set categories', user.name, user.id)
            {:success => 'saved the categories'}
          else
            {:failure => 'failure not setted'}
          end
        end
      end

      # Delete category of user
      # POST: /api/v1/categories/delete
      # PARAMS:
      #   token:            String *required
      #   category_ids:     String *required
      # RESULTS:
      #   delete categories of user      
      post :delete do
        user = User.find_by_token params[:token]
        if user.nil?
          {:failure => 'not exists user'}
        else
          category = user.user_activity_category
          cur_categories = category.activity_category.split(",")
          params[:category_ids].delete(" ").split(",").each do |del_cat|
            cur_categories.delete(del_cat)
          end
          category.activity_category = cur_categories.join(",")
          if category.save
            GoogleAnalytics.new.event('category', 'delete categories', user.name, user.id)
            {:success => 'deleted'}
          else
            {:failure => 'failure not deleted'}
          end          
        end
      end

    end
  end
end