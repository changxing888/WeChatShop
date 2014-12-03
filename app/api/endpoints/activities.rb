module Endpoints
  class Activities < Grape::API
    include Yelp::V2::Business::Request
    
    resource :activities do

      # Activity api test
      # GET /api/v1/activities/ping
      # return 'gwangming'
      get :ping do
        { :ping => 'gwangming' }
      end
      
      # Get All Activities
      # GET: /api/v1/activities/all_activities
      # PARAMS:
      #    token: String *required
      #    page:  Integer( page number )
      # RESULTS:
      #    all activities
      get :all_activities do
        user = User.find_by_token params[:token]
        if user.present?
          cost_ids = user.cost_ids
          acts = Activity.paginate(page: params[:page], :per_page => Activity::ACTIVITY_PAGE_LIMIT)
          #_activities(cost_ids)
          my_act_ids  = user.activities.present? ? user.activities.map{|act| act.id} : []
          activities = acts.map{|act|{id:act.id.to_s,name:act.name,category:act.categories_str,venue:act.merchant_name,city:act.full_city,pricing:act.get_price,img_url:act.first_img,like:my_act_ids.include?(act.id), details:act.details(my_act_ids), activity_state:act.activity_state, activity_public:act.activity_public, user_role: act.user.try(:role), first_name:act.user.try(:first_name), last_name:act.user.try(:last_name) }}
          Activity.set_browsed_count(user, acts)
          GoogleAnalytics.new.page('/api/v1/activities/all_activities', 'all activities', user.id)
          {:success =>activities}
        else
          {:failure => "not exist this ueser "}
        end
      end
      
      # ================================================

      # Get activities by multi filter V2
      # GET: /api/v1/activities/all_activities_by_multi_filter
      # PARAMS:
      #    token:         String, *required
      #    location:      String (value is ID from http://stageapp.datezr.com/admin/activity_settings/demographics )
      #    user_ids:    String (not set for now)
      #    category_ids:  String
      #    page:           Integer( page number )
      #    only_favorites: Integer(1 or 0)

      # RESULTS:
      #    activities JSON data
      get :all_activities_by_multi_filter_V2 do
        user = User.find_by_token params[:token]
        is_current_location = false

        if user.present?
          #show activities only for selected contact_id
          if (params[:user_ids].present? && params[:user_ids] == "me")
            contact_id_user = user
          elsif params[:user_ids].present?
            find_user = User.find(params[:user_ids])
            contact_id_user = find_user if find_user.present?
          end
            
          # if Rails.env.production?
          #     params[:day] = "" if params[:day] == "any"
          #     redis_data = REDIS.get("all_activities_by_multi_filter_#{params[:token]}_#{params[:location]}_#{params[:category]}_#{params[:user_ids]}_#{params[:category_ids]}_#{params[:day]}_#{params[:wday]}_#{params[:pod_ids]}_#{params[:durations]}")
          #     if redis_data.present?
          #       sotted_acts = JSON.parse(redis_data)
          #       if sotted_acts.present?
          #         page = params[:page].present? ? params[:page].to_i : 1
          #         st_pos = (page - 1) * Activity::ACTIVITY_PAGE_LIMIT
          #         ed_pos = st_pos + Activity::ACTIVITY_PAGE_LIMIT
          #         acts = sotted_acts[st_pos..ed_pos-1]
          #         acts = acts.present? ? acts : []
          #         my_act_ids  = user.activities.present? ? user.activities.map{|act| act.id} : []
          #         activities = []
          #         acts.each do |act_id|
          #           act = Activity.unsponsored_activities.where(id:act_id).first
          #           activities << {id:act.id.to_s,name:act.name,category:act.categories_str,venue:act.merchant_name,city:act.full_city,pricing:act.get_price,img_url:act.first_img,like:my_act_ids.include?(act.id),sponsored:act.sponsored, details:act.details(my_act_ids), activity_state:act.activity_state, activity_public:act.activity_public, user_role: act.user.try(:role), first_name:act.user.try(:first_name), last_name:act.user.try(:last_name)} if act.present?
          #         end
          #         return {:success =>activities}
          #       end
          #     end
          # end

          # Filtering by categories ids          
          if params[:category_ids].present?
            categories = Category.in(id:params[:category_ids].split(","))
            cat_acts = []
            if categories.present?
              categories.each do |cat|
                cat_acts = cat_acts | cat.activities.unsponsored_activities
                #.in(cost_ids:user.cost_ids)
              end
            end
          end

          if params[:location].present?
            # location filter-> first case : All neighborhood
            if Location.where(id: params[:location]).try(:first).present?
              params[:location] = Location.find(params[:location]).name
              city_name = params[:location].split(',').first
            else
              if params[:location].split(',').count == 4
                city_name = params[:location].split(',')[1].strip
                is_current_location = true
              else
                city_name = params[:location]
                is_current_location = true
              end
            end

            if is_current_location == true
              if contact_id_user.present?
                location_acts = Activity.activities_by_current_location(contact_id_user,params[:location])
              else
                location_acts = Activity.activities_by_current_location(user,params[:location])
              end
            else
              city = Location.where({:name => /^#{city_name.strip}$/i}).first
              if city.present?
                m_location_ids = Merchant.in({city: /^#{city.name.strip}$/i, active:true}).map{|m| m.id.to_s}
              else
                m_location_ids = []
              end
              
              if contact_id_user.present?
                loc_acts_ids  = Activity.where(user: contact_id_user).in(merchant_id:m_location_ids).map{|a| a.id.to_s}
              else
                loc_acts_ids = Activity.in(merchant_id:m_location_ids).map{|a| a.id.to_s}
              end
              #, cost_ids:user.cost_ids
              mine_acts_ids   = user.preference_activities.map{|a| a.id.to_s}
              f_ids = loc_acts_ids & mine_acts_ids
              s_ids = loc_acts_ids - f_ids

              if contact_id_user.present?
                first_set_acts = Activity.where(user: contact_id_user).find(f_ids).sort{rand-0.5}
              else
                first_set_acts = Activity.find(f_ids).sort{rand-0.5}
              end

              if contact_id_user.present?
                second_set_acts  = Activity.where(user: contact_id_user).find(s_ids).sort{rand-0.5}
              else
                second_set_acts  = Activity.find(s_ids).sort{rand-0.5}
              end

              # location filter-> second case : All not neighborhood
              m_nearby_ids    = Merchant.find_by_location(params[:location], GeoLocation::NEAR_BY_LIMIT)
              m_nearby_ids    = m_nearby_ids - m_location_ids

              if contact_id_user.present?
                near_acts       = Activity.where(user: contact_id_user).in(merchant_id:m_nearby_ids)
              else
                near_acts       = Activity.in(merchant_id:m_nearby_ids)
              end
              
              #, cost_ids:user.cost_ids
              near_act_ids    = near_acts.map{|a| a.id.to_s}
              t_ids = near_act_ids & mine_acts_ids
              f_ids = near_act_ids - t_ids
              third_set_acts   = Merchant.sort_from_activity_id(t_ids, m_nearby_ids)
              fourth_set_acts  = Merchant.sort_from_activity_id(f_ids, m_nearby_ids)

              if params[:category] == 'mine'
                location_acts = first_set_acts | third_set_acts
              else
                location_acts = first_set_acts | second_set_acts | third_set_acts | fourth_set_acts
              end  
              
              if cat_acts.present?
                location_acts = location_acts & cat_acts
              end
            end
          else
            if contact_id_user.present?
              location_acts = Activity.where(user: contact_id_user) 
            else
              location_acts = Activity.all
            end
          end

          if location_acts.present?
            query = "/api/v1/activities/all_activities_by_multi_filter?token=#{params[:token]}&location=#{params[:location]}&category=#{params[:category]}&category_ids=#{params[:category_ids]}&day=#{params[:day]}&wday=#{params[:wday]}&pod_ids=#{params[:pod_ids]}&durations=#{params[:durations]}"
            user.reports.create(location:params[:location],
                                interests: params[:category_ids].present? ? params[:category_ids] : params[:category],
                                day:params[:day],
                                time:params[:pod_ids],
                                type_of_search:Report::TYPE_OF_SEARCH[0],
                                results:location_acts.map{|a| a.id.to_s}.join(","))
            
            page = params[:page].to_i > 0 ? params[:page].to_i : 1
            st_pos = (page - 1) * Activity::ACTIVITY_PAGE_LIMIT
            ed_pos = st_pos + Activity::ACTIVITY_PAGE_LIMIT

            final_acts = []
            location_acts.each do |location_activity|
              if contact_id_user.present?
                if location_activity.user_id == contact_id_user.id
                  final_acts << location_activity
                end
              else
                if location_activity.activity_state == "1"
                  final_acts << location_activity
                else
                  if location_activity.user_id == user.id
                    final_acts << location_activity
                  end
                end
              end
            end

            final_acts = final_acts.uniq if final_acts.present?
            acts = final_acts[st_pos..ed_pos-1]
            acts = acts.present? ? acts : []
          else
            acts = []
          end
          REDIS.set("all_activities_by_multi_filter_#{params[:token]}_#{params[:location]}_#{params[:category]}_#{params[:user_ids]}_#{params[:category_ids]}_#{params[:day]}_#{params[:wday]}_#{params[:pod_ids]}_#{params[:durations]}", location_acts.map{|a| a.id.to_s}.to_json) if location_acts.present?
          REDIS.expire("all_activities_by_multi_filter_#{params[:token]}_#{params[:location]}_#{params[:category]}_#{params[:user_ids]}_#{params[:category_ids]}_#{params[:day]}_#{params[:wday]}_#{params[:pod_ids]}_#{params[:durations]}", Merchant::REDIS_EXPIRE_TIME)
          my_act_ids  = user.activities.present? ? user.activities.map{|act| act.id} : []
          liked_acts_ids = user.user_activity.activity

          activities = acts.map do |act|
            {details:act.details(my_act_ids, liked_acts_ids)}
          end

          activities = activities.reject{ |e| e.nil? }

          if contact_id_user.present?
            Activity.set_browsed_count(contact_id_user, acts)
          else
            Activity.set_browsed_count(user, acts)
          end
          
          {:success =>activities}
        else
          {:failure => "not exist this ueser "}
        end
      end


      # Get activities by multi filter
      # GET: /api/v1/activities/all_activities_by_multi_filter
      # PARAMS:
      #    token:         String, *required
      #    location:      String, default value is current location
      #    category:      String, default value is all, mine
      #    contact_id:    String
      #    category_ids:  String
      #    day:           String, default value is any
      #    wday:          Array 
      #    pod_ids:       Array, defalut value is any
      #    durations:     Array
      #    page:  Integer( page number )
      # RESULTS:
      #    activities JSON data
      get :all_activities_by_multi_filter do
        user = User.find_by_token params[:token]
        is_current_location = false

        if user.present?          
          if Rails.env.production?
            params[:day] = "" if params[:day] == "any"
            redis_data = REDIS.get("all_activities_by_multi_filter_#{params[:token]}_#{params[:location]}_#{params[:category]}_#{params[:contact_id]}_#{params[:category_ids]}_#{params[:day]}_#{params[:wday]}_#{params[:pod_ids]}_#{params[:durations]}")
            if redis_data.present?
              sotted_acts = JSON.parse(redis_data)
              if sotted_acts.present?
                page = params[:page].present? ? params[:page].to_i : 1
                st_pos = (page - 1) * Activity::ACTIVITY_PAGE_LIMIT
                ed_pos = st_pos + Activity::ACTIVITY_PAGE_LIMIT
                acts = sotted_acts[st_pos..ed_pos-1]
                acts = acts.present? ? acts : []
                my_act_ids  = user.activities.present? ? user.activities.map{|act| act.id} : []
                activities = []
                acts.each do |act_id|
                  act = Activity.unsponsored_activities.where(id:act_id).first
                  activities << {id:act.id.to_s,name:act.name,category:act.categories_str,venue:act.merchant_name,city:act.full_city,pricing:act.get_price,img_url:act.first_img,like:my_act_ids.include?(act.id),sponsored:act.sponsored, details:act.details(my_act_ids), activity_state:act.activity_state, activity_public:act.activity_public, user_role: act.user.try(:role), first_name:act.user.try(:first_name), last_name:act.user.try(:last_name)} if act.present?
                end
                return {:success =>activities}
              end
            end
          end

          # Filtering by categories ids          
          if params[:category_ids].present?
            categories = Category.in(id:params[:category_ids].split(","))
            cat_acts = []
            if categories.present?
              categories.each do |cat|
                cat_acts = cat_acts | cat.activities.unsponsored_activities
                #.in(cost_ids:user.cost_ids)
              end
            end
          end

          # Filtering by specific day or weeks filter
          # if params[:day].present?
          #   if params[:day] == 'any'
          #     hours_acts = Activity.unsponsored_activities
          #     #_activities(user.cost_ids)
          #   else
          #     st_dt = DateTime.strptime(params[:day],'%Y-%m-%d')
          #     ed_dt = DateTime.strptime(params[:day]+'-23','%Y-%m-%d-%H') 
          #     hours_acts = Activity.unsponsored_activities.where(:st_date=>{:$lte=>ed_dt, :$gt => st_dt})
          #     if hours_acts.blank?
          #       wday = params[:day].to_date.wday              
          #       act_hours = ActivityHour.where(week:wday)
          #       m_ids = act_hours.map{|ah| ah.merchant.id.to_s}
          #       hours_acts = Activity.unsponsored_activities.in(merchant_id:m_ids).reject{|act| act.is_active? == false}
          #       #,cost_ids:user.cost_ids
          #     end
          #   end
          # elsif params[:wday]
          #   today = Date.today
          #   today_week = today.wday
          #   w_days = []   
          #   selected_days = []
          #   params[:wday].split(',').each do |w|
          #     if w.to_i < today_week.to_i
          #       w_day = w.to_i + 7 - today_week.to_i
          #     else
          #       w_day = w.to_i - today_week.to_i
          #     end
          #     w_days << w_day
          #   end            
          #   w_days.each do |wd|
          #     selected_dt = today + wd.to_i.days
          #     selected_days = selected_days | [*0..23].map{|d| selected_dt.to_datetime+d.hours}
          #   end
          #   hours_acts = Activity.unsponsored_activities.in(st_date:selected_days)
          #   if hours_acts.blank?
          #     wdays = params[:wday].split(",")
          #     act_hours = ActivityHour.in(week:wdays)
          #     m_ids = act_hours.map{|ah| ah.merchant.id.to_s}
          #     hours_acts = Activity.unsponsored_activities.in(merchant_id:m_ids).reject{|act| act.is_active? == false}
          #     #,cost_ids:user.cost_ids
          #   end
          # end


          if params[:day].present?
            if params[:day] == 'any'
              wday = Time.now.wday
            else
              wday = DateTime.strptime(params[:day],'%Y-%m-%d').wday
            end

            if wday == 0
              wday = 6
            else
              wday = wday -1
            end
            hours_acts = Activity.unsponsored_activities.where({:best_days=>Regexp.new(".*"+wday.to_s+".*")})
          elsif params[:wday]
            w_activities = ""
            wdays = params[:wday].split(",")
            wdays.each do |w|
              acts_ids = Activity.unsponsored_activities.where({:best_days=>Regexp.new(".*"+w+".*")}).map{|a| a.id.to_s}
              w_activities = w_activities + acts_ids.join(",") + ","
            end
            w_activities.chop!
            hours_acts = Activity.unsponsored_activities.in(id:w_activities.split(","))
          end


          # Filtering by time filter or duration filter
          pod_ids = params[:pod_ids].delete(" ").split(",") if params[:pod_ids].present? and params[:pod_ids] != 'any'
          durations = params[:durations].delete(" ").split(",") if params[:durations].present? and params[:durations] != 'any'
          if pod_ids.present? and durations.present?
            pod_ids_acts = Activity.unsponsored_activities.in(parts_of_day_ids:pod_ids)
            durations_acts = Activity.unsponsored_activities.in(timeframe_ids:duration)
            all_acts = pod_ids_acts | durations_acts
            time_acts = Activity.unsponsored_activities.in(id:all_acts.map(&:id))
          elsif pod_ids.present?
            time_acts = Activity.unsponsored_activities.in(parts_of_day_ids:pod_ids)
          elsif durations.present?
            time_acts = Activity.unsponsored_activities.in(timeframe_ids:duration)
          end

          if params[:location].present?
            # location filter-> first case : All neighborhood
            if params[:location].split(',').count == 4
              city_name = params[:location].split(',')[1].strip
              is_current_location = true
            else
              city_name = params[:location].split(',').first
            end


            if is_current_location == true
              location_acts = Activity.activities_by_current_location(user,params[:location])
            else
              city = Location.where({:name => /^#{city_name.strip}$/i}).first
              if city.present?
                m_location_ids = Merchant.in({city: /^#{city.name.strip}$/i, active:true}).map{|m| m.id.to_s}
              else
                m_location_ids = []
              end

              loc_acts_ids    = Activity.unsponsored_activities.in(merchant_id:m_location_ids).map{|a| a.id.to_s}
              #, cost_ids:user.cost_ids
              mine_acts_ids   = user.preference_activities.map{|a| a.id.to_s}
              f_ids = loc_acts_ids & mine_acts_ids
              s_ids = loc_acts_ids - f_ids
              first_set_acts   = Activity.unsponsored_activities.find(f_ids).sort{rand-0.5}
              second_set_acts  = Activity.unsponsored_activities.find(s_ids).sort{rand-0.5}

              # location filter-> second case : All not neighborhood
              m_nearby_ids    = Merchant.find_by_location(params[:location], GeoLocation::NEAR_BY_LIMIT)
              m_nearby_ids    = m_nearby_ids - m_location_ids
              near_acts       = Activity.unsponsored_activities.in(merchant_id:m_nearby_ids)
              #, cost_ids:user.cost_ids
              near_act_ids    = near_acts.map{|a| a.id.to_s}
              t_ids = near_act_ids & mine_acts_ids
              f_ids = near_act_ids - t_ids
              third_set_acts   = Merchant.sort_from_activity_id(t_ids, m_nearby_ids)
              fourth_set_acts  = Merchant.sort_from_activity_id(f_ids, m_nearby_ids)

              if params[:category] == 'mine'
                location_acts = first_set_acts | third_set_acts
              else
                location_acts = first_set_acts | second_set_acts | third_set_acts | fourth_set_acts
              end  
              
              if cat_acts.present?
                location_acts = location_acts & cat_acts
              elsif hours_acts.present?
                location_acts = location_acts & hours_acts
              elsif time_acts.present?
                location_acts = location_acts & time_acts
              end
            end
            
          end

          # Get sponsored activities          
          location = params[:location].split(",")
          if location.count == 1 || location.count==2
            city = Location.where({:name => /^#{location[0].strip}$/i}).first
          else
            city = Location.where({:name => /^#{location[1].strip}$/i}).first
          end


        # insert sponsored activities to searched activities          
          sponsored_activity = city.sponsored_activity
          if location_acts.present? and sponsored_activity.present? and sponsored_activity.active
            start_index = sponsored_activity.start_index.to_i
            increment = sponsored_activity.increment.to_i
            s_acts = sponsored_activity.all_active_activities

            i = 0
            j = 0
            k = 0
 
            while location_acts[i].present? do
              k = 0 if k == s_acts.count
              if i == 0
                location_acts.insert(start_index, s_acts[k])
                k += 1
              else
                location_acts.insert(i, s_acts[k])
                k += 1
              end
              j += 1
              i = j * increment + start_index
            end
          end



          if location_acts.present?
            query = "/api/v1/activities/all_activities_by_multi_filter?token=#{params[:token]}&location=#{params[:location]}&category=#{params[:category]}&category_ids=#{params[:category_ids]}&day=#{params[:day]}&wday=#{params[:wday]}&pod_ids=#{params[:pod_ids]}&durations=#{params[:durations]}"
            user.reports.create(location:params[:location],
                                interests: params[:category_ids].present? ? params[:category_ids] : params[:category],
                                day:params[:day],
                                time:params[:pod_ids],
                                type_of_search:Report::TYPE_OF_SEARCH[0],
                                results:location_acts.map{|a| a.id.to_s}.join(","))
            
            page = params[:page].to_i > 0 ? params[:page].to_i : 1
            st_pos = (page - 1) * Activity::ACTIVITY_PAGE_LIMIT
            ed_pos = st_pos + Activity::ACTIVITY_PAGE_LIMIT
            
            acts = location_acts[st_pos..ed_pos-1]
            acts = acts.present? ? acts : []
          else
            acts = []
          end
          REDIS.set("all_activities_by_multi_filter_#{params[:token]}_#{params[:location]}_#{params[:category]}_#{params[:contact_id]}_#{params[:category_ids]}_#{params[:day]}_#{params[:wday]}_#{params[:pod_ids]}_#{params[:durations]}", location_acts.map{|a| a.id.to_s}.to_json) if location_acts.present?
          REDIS.expire("all_activities_by_multi_filter_#{params[:token]}_#{params[:location]}_#{params[:category]}_#{params[:contact_id]}_#{params[:category_ids]}_#{params[:day]}_#{params[:wday]}_#{params[:pod_ids]}_#{params[:durations]}", Merchant::REDIS_EXPIRE_TIME)
          my_act_ids  = user.activities.present? ? user.activities.map{|act| act.id} : []
          activities = acts.map{|act|{id:act.id.to_s,name:act.name,category:act.categories_str,venue:act.merchant_name,city:act.full_city,pricing:act.get_price,img_url:act.first_img,like:my_act_ids.include?(act.id),sponsored:act.sponsored, details:act.details(my_act_ids), activity_public:act.activity_public, user_role: act.user.try(:role), first_name:act.user.try(:first_name), last_name:act.user.try(:last_name)}}
          Activity.set_browsed_count(user, acts)
          {:success =>activities}
        else
          {:failure => "not exist this ueser "}
        end
      end

      # Added Activities
      # GET: /api/v1/activities/added_activities
      # PARAMS:
      #    token: String *required
      # RESULTS:
      #    activities for provided user
      get :added_activities do
        user = User.find_by_token params[:token]
        if user.present?
          my_activities = user.available_activities
          #my_act_ids  = user.available_activities.present? ? user.available_activities.map{|act| act.id} : []

          if my_activities.blank?
            return {failure: "cannot find activities for provided user"}
          end

          my_act_ids  = user.available_activities.present? ? user.available_activities.map{|act| act.id} : []
          activities = my_activities.map{|act|{id:act.id.to_s,name:act.name,category:act.categories_str,venue:act.merchant_name,city:act.full_city,pricing:act.get_price,img_url:act.first_img, details:act.details(my_act_ids), activity_state:act.activity_state, activity_public:act.activity_public, user_role: act.user.try(:role), first_name:act.user.try(:first_name), last_name:act.user.try(:last_name) }}
          {:success =>activities}
        else
          {:failure => "user don't exist"}
        end
      end
      

      # Get activities by multi filter
      # GET: /api/v1/activities/my_activities_by_multi_filter
      # PARAMS:
      #    token:     String, *required
      #    location:  String, default value is current location
      #    category:  String, default value is all, mine
      #    user_ids:    String
      #    category_ids:  String
      #    day:       String, default value is any
      #    wday:      Array 
      #    pod_ids:   Array, defalut value is any
      #    durations: Array
      #    page:  Integer( page number )
      # RESULTS:
      #    activities JSON data
      get :my_activities_by_multi_filter do
        user = User.find_by_token params[:token]        
        #location filter
        
        if user.present?
          #   category filter
          redis_data = REDIS.get("my_activities_by_multi_filter_#{params[:token]}_#{params[:location]}_#{params[:category]}_#{params[:user_ids]}_#{params[:category_ids]}_#{params[:day]}_#{params[:wday]}_#{params[:pod_ids]}_#{params[:durations]}")
          if redis_data.present?
            sotted_acts = JSON.parse(redis_data)
            if sotted_acts.present?
              page = params[:page].present? ? params[:page].to_i : 1
              st_pos = (page - 1) * Activity::ACTIVITY_PAGE_LIMIT
              ed_pos = st_pos + Activity::ACTIVITY_PAGE_LIMIT
              acts = sotted_acts[st_pos..ed_pos-1]
              acts = acts.present? ? acts : []
              my_act_ids  = user.activities.present? ? user.activities.map{|act| act.id} : []
              activities = []
              acts.each do |act_id|
                act = Activity.where(id:act_id).first
                activities << {id:act.id.to_s,name:act.name,category:act.categories_str,venue:act.merchant_name,city:act.full_city,pricing:act.get_price,img_url:act.first_img,like:my_act_ids.include?(act.id), sponsored:act.sponsored, details:act.details(my_act_ids), activity_state:act.activity_state, activity_public:act.activity_public, user_role: act.user.try(:role), first_name:act.user.try(:first_name), last_name:act.user.try(:last_name)} if act.present?
              end
              return {:success =>activities}
            end
          end

          my_activities = user.available_activities
          if my_activities.blank?
            return {failure: "cannot find my activities"}
          end

          # Filtering by categories ids
          if params[:category_ids].present?
            categories = Category.in(id:params[:category_ids].split(","))
            cat_acts = []
            if categories.present?
              categories.each do |cat|
                cat_acts = cat_acts | cat.activities
                #.in(cost_ids:user.cost_ids)
              end
            end
          end

          if params[:day].present?
            if params[:day] == 'any'
              hours_acts = my_activities
            else
              wday = DateTime.strptime(params[:day],'%Y-%m-%d').wday
              if wday == 0
                wday = 6
                hours_acts = my_activities.where({:best_days=>Regexp.new(".*"+wday.to_s+".*")})
              else
                wday = wday -1
                hours_acts = my_activities.where({:best_days=>Regexp.new(".*"+wday.to_s+".*")})
              end
            end
          elsif params[:wday]
            w_activities = ""
            wdays = params[:wday].split(",")
            wdays.each do |w|
              acts_ids = my_activities.where({:best_days=>Regexp.new(".*"+w+".*")}).map{|a| a.id.to_s}
              w_activities = w_activities + acts_ids.join(",") + ","
            end
            w_activities.chop!
            hours_acts = my_activities.in(id:w_activities.split(","))
          end

          # Filtering by time filter or duration filter
          pod_ids = params[:pod_ids].delete(" ").split(",") if params[:pod_ids].present? and params[:pod_ids] != 'any'
          durations = params[:durations].delete(" ").split(",") if params[:durations].present? and params[:durations] != 'any'
          if pod_ids.present? and durations.present?
            pod_ids_acts = my_activities.in(parts_of_day_ids:pod_ids)
            durations_acts = my_activities.in(timeframe_ids:duration)
            all_acts = pod_ids_acts | durations_acts
            time_acts = my_activities.in(id:all_acts.map(&:id))
          elsif pod_ids.present?
            time_acts = my_activities.in(parts_of_day_ids:pod_ids)
          elsif durations.present?
            time_acts = my_activities.in(timeframe_ids:duration)
          end



          if params[:location].present?
            # location filter-> first case : All neighborhood
            if params[:location].split(',').count > 2 
              city_name = params[:location].split(',')[1].strip
            else
              city_name = params[:location].split(',').first
            end
            city = Location.where({:name => /^#{city_name.strip}$/i}).first
            if city.present?
              m_location_ids = Merchant.in({city: /^#{city.name.strip}$/i, active:true}).map{|m| m.id.to_s}
            else
              m_location_ids = []
            end

            loc_acts_ids    = my_activities.in(merchant_id:m_location_ids).map{|a| a.id.to_s}
            #, cost_ids:user.cost_ids
            mine_acts_ids   = user.preference_activities.map{|a| a.id.to_s}
            f_ids = loc_acts_ids & mine_acts_ids
            s_ids = loc_acts_ids - f_ids
            first_set_acts   = my_activities.find(f_ids).sort{rand-0.5}
            second_set_acts  = my_activities.find(s_ids).sort{rand-0.5}

            # location filter-> second case : All not neighborhood
            m_nearby_ids    = Merchant.find_by_location(params[:location], GeoLocation::NEAR_BY_LIMIT)
            m_nearby_ids    = m_nearby_ids - m_location_ids
            near_acts       = my_activities.in(merchant_id:m_nearby_ids)
            #, cost_ids:user.cost_ids
            near_act_ids    = near_acts.map{|a| a.id.to_s}
            t_ids = near_act_ids & mine_acts_ids
            f_ids = near_act_ids - t_ids
            third_set_acts   = Merchant.sort_from_activity_id(t_ids, m_nearby_ids)
            fourth_set_acts  = Merchant.sort_from_activity_id(f_ids, m_nearby_ids)

            if params[:category] == 'mine'
              location_acts = first_set_acts | third_set_acts
            else
              location_acts = first_set_acts | second_set_acts | third_set_acts | fourth_set_acts
            end  
            
            if cat_acts.present?
              location_acts = location_acts & cat_acts
            elsif hours_acts.present?
              location_acts = location_acts & hours_acts
            elsif time_acts.present?
              location_acts = location_acts & time_acts
            end
          end

          # insert sponsored activities to searched activities          
          sponsored_activity = city.sponsored_activity
          if location_acts.present? and sponsored_activity.present? and sponsored_activity.active
            start_index = sponsored_activity.start_index.to_i
            increment = sponsored_activity.increment.to_i
            s_acts = sponsored_activity.all_active_activities

            i = 0
            j = 0
            k = 0
            while location_acts[i].present? do
              k = 0 if k == s_acts.count
              if i == 0
                location_acts.insert(start_index, s_acts[k])
                k += 1
              else
                location_acts.insert(i, s_acts[k])
                k += 1
              end
              j += 1
              i = j * increment + start_index
            end

            # acts.each_with_index do |act, index|
            #   if index==0
            #     location_acts.insert(start_index,act) if location_acts.count > start_index
            #   else
            #     point = index * increment + start_index
            #     break if point > location_acts.count
            #     location_acts.insert(point, act)
            #   end
            # end 

          end
          
          if location_acts.present?

            user.reports.create(location:params[:location],
                                interests: params[:category_ids].present? ? params[:category_ids] : params[:category],
                                day:params[:day],
                                time:params[:pod_ids],
                                type_of_search:Report::TYPE_OF_SEARCH[1],
                                results:location_acts.map{|a| a.id.to_s}.join(","))
            
            page = params[:page].to_i > 0 ? params[:page].to_i : 1
            st_pos = (page - 1) * Activity::ACTIVITY_PAGE_LIMIT
            ed_pos = st_pos + Activity::ACTIVITY_PAGE_LIMIT
            
            acts = location_acts[st_pos..ed_pos-1]
            acts = acts.present? ? acts : []
          else
            acts = []
          end
          REDIS.set("my_activities_by_multi_filter_#{params[:token]}_#{params[:location]}_#{params[:category]}_#{params[:contact_id]}_#{params[:category_ids]}_#{params[:day]}_#{params[:wday]}_#{params[:pod_ids]}_#{params[:durations]}", location_acts.map{|a| a.id.to_s}.to_json) if location_acts.present?
          REDIS.expire("my_activities_by_multi_filter_#{params[:token]}_#{params[:location]}_#{params[:category]}_#{params[:contact_id]}_#{params[:category_ids]}_#{params[:day]}_#{params[:wday]}_#{params[:pod_ids]}_#{params[:durations]}", Merchant::REDIS_EXPIRE_TIME)
          my_act_ids  = user.activities.present? ? user.activities.map{|act| act.id} : []
          activities = acts.map{|act|{id:act.id.to_s,name:act.name,category:act.categories_str,venue:act.merchant_name,city:act.full_city,pricing:act.get_price,img_url:act.first_img,like:my_act_ids.include?(act.id),sponsored:act.sponsored, details:act.details(my_act_ids), user_role: act.user.try(:role), first_name:act.user.try(:first_name), last_name:act.user.try(:last_name)}}
          Activity.set_browsed_count(user, acts)
          {:success =>activities}
        else
          {:failure => "not exist this ueser "}
        end
      end

      # Get activities by location
      # GET: /api/v1/activities/activities_by_location
      # PARAMS:
      #    token:     String *required
      #    location:  String *required
      #    page:      Integer( page number )
      # RESULTS:
      #    activities by location
      get :activities_by_location do
        return {:failure => "input location"} if params[:location].blank?        
        
        #city = Location.where(:name=>params[:location]).first
        user = User.find_by_token params[:token]
        m_loc_ids = []
        
        {failure: "please select location"} if params[:location].blank?

        if user.present?
          if params[:location].present?
            # location filter-> first case : All neighborhood
            city_name = params[:location].split(',').first
            city = Location.where(name:city_name.strip).first
            if city.present?
              m_location_ids = Merchant.in({city: city.name, active:true}).map{|m| m.id.to_s}
            end

            loc_acts_ids    = Activity.unsponsored_activities.in(merchant_id:m_location_ids).map{|a| a.id.to_s}
            #, cost_ids:user.cost_ids
            mine_acts_ids   = user.preference_activities.map{|a| a.id.to_s}
            f_ids = loc_acts_ids & mine_acts_ids
            s_ids = loc_acts_ids - f_ids
            first_set_acts   = Activity.find(f_ids).sort{rand-0.5}
            second_set_acts  = Activity.find(s_ids).sort{rand-0.5}

            # location filter-> second case : All not neighborhood
            m_nearby_ids    = Merchant.find_by_location(params[:location], GeoLocation::NEAR_BY_LIMIT)
            m_nearby_ids    = m_nearby_ids - m_location_ids
            near_acts       = Activity.in(merchant_id:m_nearby_ids)
            #, cost_ids:user.cost_ids
            near_act_ids    = near_acts.map{|a| a.id.to_s}
            t_ids = near_act_ids & mine_acts_ids
            f_ids = near_act_ids - t_ids
            third_set_acts   = Merchant.sort_from_activity_id(t_ids, m_nearby_ids)
            fourth_set_acts  = Merchant.sort_from_activity_id(f_ids, m_nearby_ids)
            
            location_acts = first_set_acts | second_set_acts | third_set_acts | fourth_set_acts
            
          end

          if location_acts.present?            
            page = params[:page].to_i > 0 ? params[:page].to_i : 1
            st_pos = (page - 1) * Activity::ACTIVITY_PAGE_LIMIT
            ed_pos = st_pos + Activity::ACTIVITY_PAGE_LIMIT
            
            acts = location_acts[st_pos..ed_pos-1]
            acts = acts.present? ? acts : []
          else
            acts = []
          end
          
          my_act_ids  = user.activities.present? ? user.activities.map{|act| act.id} : []
          activities = acts.map{|act|{id:act.id.to_s,name:act.name,category:act.categories_str,venue:act.merchant_name,city:act.full_city,pricing:act.get_price,img_url:act.first_img,like:my_act_ids.include?(act.id), details:act.details(my_act_ids), activity_state:act.activity_state, activity_public:act.activity_public, user_role: act.user.try(:role), first_name:act.user.try(:first_name), last_name:act.user.try(:last_name)}}
          Activity.set_browsed_count(user, acts)
          {:success =>activities}
          
        else
          {:failure => "not exist this ueser "}
        end
      end
      
      # Get activities by category
      # GET: /api/v1/activities/activities_by_category
      # PARAMS:
      #    token:     String *required
      #    category:  String *required #category id
      #    page:      Integer( page number )
      # RESULTS:
      #    activities by category
      get :activities_by_category do
        return {:failure => "input location"} if params[:category].blank?
        user = User.find_by_token params[:token]
        if user.present?
          category = Category.find(params[:category])
          my_act_ids  = user.activities.present? ? user.activities.map{|act| act.id} : []
          acts = category.activities.paginate(page: params[:page], :per_page => Activity::ACTIVITY_PAGE_LIMIT)
          #.in(cost_ids:user.cost_ids)
          activities = acts.map{|act|{id:act.id.to_s,name:act.name,category:act.categories_str,venue:act.merchant_name,city:act.full_city,pricing:act.get_price,img_url:act.first_img,like:my_act_ids.include?(act.id), details:act.details(my_act_ids), activity_state:act.activity_state, activity_public:act.activity_public, user_role: act.user.try(:role), first_name:act.user.try(:first_name), last_name:act.user.try(:last_name)}}

          Activity.set_browsed_count(user, acts)

          sh = user.search_histories.where(search_name: params[:category], search_type: SearchHistory::SEARCH_TYPE[1], search_option: SearchHistory::SEARCH_OPTIONS[0]).first
          if sh.present?
            count = sh.search_count.to_i + 1
            sh.update_attribute(:search_count, count)
          else
            sh = user.search_histories.build(search_name: params[:location], search_type: SearchHistory::SEARCH_TYPE[1], search_option: SearchHistory::SEARCH_OPTIONS[0], search_count: 0)
            sh.save
          end
          GoogleAnalytics.new.page('/api/v1/activities/activities_by_category', 'get activities by category', user.id)
          {:success =>activities}
        else
          {:failure => "not exist this ueser "}
        end
      end

      # Get activities by day
      # GET: /api/v1/activities/activities_by_day
      # PARAMS:
      #    token:     String *required
      #    day:       String *required "2013-11-25"
      #    wday:      String optional   5 # 5 is friday
      #    offset:    String
      # RESULTS:
      #    activities by day
      get :activities_by_day do        
        return {:failure => "input day"} if params[:day].blank? and params[:wday].blank?
        wday = params[:day].blank? ? params[:wday].to_i : params[:day].to_date.wday
        user = User.find_by_token params[:token]
        if user.present?
          act_hours = ActivityHour.where(week:wday)
          m_ids = act_hours.map{|ah| ah.merchant.id.to_s}

          return {failure:"cannot find activities for the day"} if m_ids.blank?
          acts = Activity.in(merchant_id:m_ids).reject{|act| act.is_active? == false} #.paginate(page: params[:offset], :per_page => 5)
          #,cost_ids:user.cost_ids
          my_act_ids  = user.activities.present? ? user.activities.map{|act| act.id} : []
          activities = acts.map{|act|{id:act.id.to_s,name:act.name,category:act.categories_str,venue:act.merchant_name,city:act.full_city,pricing:act.get_price,img_url:act.first_img,like:my_act_ids.include?(act.id), details:act.details(my_act_ids), user_role: act.user.try(:role), first_name:act.user.try(:first_name), last_name:act.user.try(:last_name)}}
          
          Activity.set_browsed_count(user, acts)

          sh = user.search_histories.where(search_name: wday, search_type: SearchHistory::SEARCH_TYPE[2], search_option: SearchHistory::SEARCH_OPTIONS[0]).first
          if sh.present?
            count = sh.search_count.to_i + 1
            sh.update_attribute(:search_count, count)
          else
            sh = user.search_histories.build(search_name: wday, search_type: SearchHistory::SEARCH_TYPE[2], search_option: SearchHistory::SEARCH_OPTIONS[0], search_count: 0)
            sh.save
          end
          GoogleAnalytics.new.page('/api/v1/activities/activities_by_day', 'get activities by day', user.id)
          {:success =>activities}
        else
          {:failure => "not exist this ueser "}
        end
      end

      # Get activities by time
      # GET: /api/v1/activities/activities_by_time
      # PARAMS:
      #    token:         String *required
      #    pod_ids:       String *required 
      #    duration:      String optional   
      # RESULTS:
      #    activities by time
      get :activities_by_time do
        user = User.find_by_token params[:token]
        if user.present?
          pod_ids = params[:pod_ids].delete(" ").split(",")

          all_acts = []
          pod_ids.each do |p_id|
            all_acts = all_acts | Activity.where({:parts_of_day_ids => /.*#{p_id}*./}).reject{|act| act.is_active? == false}
            #.in(cost_ids:user.cost_ids)
          end

          if all_acts.first.nil?
            {:failure => "cannot find this activities"}
          else
            my_act_ids  = user.activities.present? ? user.activities.map{|act| act.id} : []
            activities = all_acts.map{|act|{id:act.id.to_s,name:act.name,category:act.categories_str,venue:act.merchant_name,city:act.full_city,pricing:act.get_price,img_url:act.first_img,like:my_act_ids.include?(act.id), details:act.details(my_act_ids), user_role: act.user.try(:role), first_name:act.user.try(:first_name), last_name:act.user.try(:last_name)}}

            Activity.set_browsed_count(user, all_acts)

            GoogleAnalytics.new.page('/api/v1/activities/activities_by_time', 'get activities by time', user.id)

            {success: activities}
          end
        else
          {:failure => "not exist this ueser "}
        end
      end

      # Get All Activities of user
      # GET: /api/v1/activities/activities
      # PARAMS:
      #    token: String *required
      #    page:      Integer( page number )
      # RESULTS:
      #    all activities of user
      get :activities do
        user = User.find_by_token params[:token]
        if user.present?
          acts = user.available_activities.paginate(page: params[:page], :per_page => Activity::ACTIVITY_PAGE_LIMIT)
          my_act_ids  = user.activities.present? ? user.activities.map{|act| act.id} : []
          if acts.first.nil?
            {:failure => "not exist my activities"}  
          else
            activities = acts.map{|act|{id:act.id.to_s,name:act.name,category:act.categories_str,venue:act.merchant_name,city:act.full_city,pricing:act.get_price,img_url:act.first_img, details:act.details(my_act_ids), user_role: act.user.try(:role), first_name:act.user.try(:first_name), last_name:act.user.try(:last_name)}}
            GoogleAnalytics.new.page('/api/v1/activities/activities', 'get activities of user', user.id)
            {:success =>activities}
          end
        else
          {:failure => "not exist this ueser "}
        end
      end

      # Get Activity details
      # GET: /api/v1/activities/activity
      # PARAMS:
      #    token:       String *required
      #    activity_id: String *required
      # RESULTS:
      #    activity details that selected activity id
      get :activity do
        user = User.find_by_token params[:token]
        if user.present?
          activity = Activity.where(id: params[:activity_id])
          my_act_ids  = user.activities.present? ? user.activities.map{|act| act.id} : []
          if activity.first.nil?
            {:failure => "not exist this activity"}  
          else
            Activity.set_viewed_count(user, activity.first)
            GoogleAnalytics.new.page('/api/v1/activities/activity', 'get activity details', user.id)

            gallery = activity.first.gallery_images_single(user, activity.first).map do |l|
              l_id = l.img_url.split("/")[6]
              unless (l_id == activity.first.first_img.split("/")[6] || l_id == activity.first.second_img.split("/")[6] || l_id == activity.first.third_img.split("/")[6])
                {id:l.id.to_s,img_url:l.img_url,state:l.state,views:l.viewed_count, user:l.user.try(:name), avatar:l.user.try(:logo_img)}
              end
            end
            gallery = gallery.reject{ |e| e.nil? }

            {:success =>activity.map{|act| {id:act.id.to_s,name:act.name,category:act.categories_str,venue:act.merchant_name,description:act.description,address:act.address,phone:act.merchant.phone,
                                            website:act.merchant.url,pricing:act.get_price,img_url1:act.first_img,img_url2:act.second_img,img_url3:act.third_img,like:my_act_ids.include?(act.id), 
                                            hours:act.hours, discount:act.discount_info, duration:act.estimated_duration, attire:act.attire_name, attire_id: act.attire.try(:id), attire_icon:act.attire_icon, 
                                            cost:act.cost_name, cost_ids: act.cost_ids, cost_icon:act.cost_icon,level:act.level_name, city:act.full_city, gallery:gallery, user_role: act.user.try(:role), 
                                            first_name:act.user.try(:first_name), last_name:act.user.try(:last_name)}}}
          end
        else
          {:failure => "not exist this ueser "}
        end
      end

      # Set Activities
      # POST: /api/v1/activities/set_activities
      # PARAMS:
      #    token:         String *required
      #    activity_ids:  String *required
      # RESULTS:
      #    success string
      post :set_activities do
        user = User.find_by_token params[:token]
        if user.present?
          u_activity = user.user_activity.present? ? user.user_activity : user.build_user_activity
          
          if u_activity.activity.present?
            cur_act_ids = u_activity.activity.split(",")
            act_ids = cur_act_ids | params[:activity_ids].delete(" ").split(",")
            u_activity.activity = act_ids.join(",")
          else
            u_activity.activity = params[:activity_ids].delete(" ")
          end

          if u_activity.save
            acts = Activity.in(id:params[:activity_ids].delete(" ").split(","))
            Activity.set_saved_count(user, acts)

            GoogleAnalytics.new.event('activity', 'set activities', user.name, user.id)
            
            {:success => "set activities"}  
          else
            {:failure => "not set activities"}
          end
        else
          {:failure => "not exist this ueser "}
        end
      end

      # Publish Activity
      # POST: /api/v1/activities/publish_activity
      # PARAMS:
      #    token:         String *required
      #    activity_id:   String *required
      # RESULTS:
      #    success string
      post :publish_activity do
        user = User.find_by_token params[:token]
        if user.present?
          activity = Activity.find(params[:activity_id])
          activity.update_attribute(:activity_public, true)

          if activity.save
            {:success => "activity published"}  
          else
            {:failure => "activity not published"}
          end
        else
          {:failure => "user don't exists"}
        end
      end

      # Delete Activities
      # POST: /api/v1/activities/delete
      # PARAMS:
      #    token:         String *required
      #    activity_ids:  String *required
      # RESULTS:
      #    success string
      post :delete do
        user = User.find_by_token params[:token]
        if user.present?
          u_activity = user.user_activity
          return {:failure => "not deleted activities"} if u_activity.nil? or u_activity.activity.blank?
          
          cur_act_ids = u_activity.activity.delete(" ").split(",")

          params[:activity_ids].delete(" ").split(",").each do |act_id|
            cur_act_ids.delete(act_id)
          end          
          
          u_activity.activity = cur_act_ids.join(",")
          
          if u_activity.save
            params[:activity_ids].delete(" ").split(",").each do |act_id|
              act = Activity.find(act_id)
              act.update_attribute(:saved_count,act.saved_count.to_i-1)
            end
            GoogleAnalytics.new.event('activity', 'delete activities', user.name, user.id)
            {:success => "deleted activities"}  
          else
            {:failure => "not deleted activities"}
          end
        else
          {:failure => "not exist this ueser "}
        end
      end

      # Get my_activities_by_location
      # GET: /api/v1/activities/my_activities_by_location
      # PARAMS:
      #    token:         String *required
      #    location:      String *required
      #    page:          Integer( page number )
      # RESULTS:
      #    get my activities by location
      get :my_activities_by_location do
        return {:failure => "input location"} if params[:location].blank?
        city = Location.where(:name=>params[:location]).first
        user = User.find_by_token params[:token]

        if city.present?
          city = city.name
        else
          return {failure: "Cannot find location"}
        end
        
        if user.present?
          if city.present?
            m_ids = Merchant.any_of({city: city}).map{|m| m.id.to_s}
            geo_acts = Activity.in(merchant_id:m_ids)
          else
            geo_acts = GeoLocation.get_activities_by_location(params[:location])
          end
          
          my_act_ids  = user.activities.present? ? user.activities.map{|act| act.id} : []
          my_acts  = user.available_activities.paginate(page: params[:page], :per_page => Activity::ACTIVITY_PAGE_LIMIT)
          acts = geo_acts & my_acts
          activities = acts.map{|act|{id:act.id.to_s,name:act.name,category:act.categories_str,venue:act.merchant_name,city:act.full_city,pricing:act.get_price,img_url:act.first_img,like:true, details:act.details(my_act_ids), activity_state:act.activity_state, activity_public:act.activity_public, user_role: act.user.try(:role), first_name:act.user.try(:first_name), last_name:act.user.try(:last_name)}}

          sh = user.search_histories.where(search_name: params[:location], search_type: SearchHistory::SEARCH_TYPE[0], search_option: SearchHistory::SEARCH_OPTIONS[0]).first
          if sh.present?
            count = sh.search_count.to_i + 1
            sh.update_attribute(:search_count, count)
          else
            sh = user.search_histories.build(search_name: params[:location], search_type: SearchHistory::SEARCH_TYPE[0], search_option: SearchHistory::SEARCH_OPTIONS[0], search_count: 0)
            sh.save
          end

          GoogleAnalytics.new.page('/api/v1/activities/my_activities_by_location', 'get my activities by location', user.id)
          
          {:success =>activities}
        else
          {:failure => "not exist this ueser "}
        end
      end
      
      # Get my_activities_by_category
      # GET: /api/v1/activities/my_activities_by_category
      # PARAMS:
      #    token:         String *required
      #    category:      String *required
      # RESULTS:
      #    get my activities by category
      get :my_activities_by_category do
        return {:failure => "input location"} if params[:category].blank?
        user = User.find_by_token params[:token]
        if user.present?
          category = Category.find(params[:category])
          cat_acts = category.activities          
          my_acts  = user.available_activities
          my_act_ids  = user.activities.present? ? user.activities.map{|act| act.id} : []
          acts = cat_acts & my_acts
          activities = acts.map{|act|{id:act.id.to_s,name:act.name,category:act.categories_str,venue:act.merchant_name,city:act.full_city,pricing:act.get_price,img_url:act.first_img,like:true, details:act.details(my_act_ids), activity_state:act.activity_state, activity_public:act.activity_public, user_role: act.user.try(:role), first_name:act.user.try(:first_name), last_name:act.user.try(:last_name)}}
          
          sh = user.search_histories.where(search_name: params[:category], search_type: SearchHistory::SEARCH_TYPE[1], search_option: SearchHistory::SEARCH_OPTIONS[0]).first
          if sh.present?
            count = sh.search_count.to_i + 1
            sh.update_attribute(:search_count, count)
          else
            sh = user.search_histories.build(search_name: params[:location], search_type: SearchHistory::SEARCH_TYPE[1], search_option: SearchHistory::SEARCH_OPTIONS[0], search_count: 0)
            sh.save
          end
          GoogleAnalytics.new.page('/api/v1/activities/my_activities_by_category', 'get my activities by category', user.id)
          {:success =>activities}
        else
          {:failure => "not exist this ueser "}
        end
      end

      # Get my activities by day
      # GET: /api/v1/activities/my_activities_by_day
      # PARAMS:
      #    token:     String *required
      #    day:       String *required "2013-11-25"
      #    wday:      String optional   5 # 5 is friday
      # RESULTS:
      #    activities by day
      get :my_activities_by_day do        
        return {:failure => "input day"} if params[:day].blank? and params[:wday].blank?        
        wday = params[:day].blank? ? params[:wday].to_i : params[:day].to_date.wday
        user = User.find_by_token params[:token]
        if user.present?
          my_acts  = user.available_activities
          my_act_ids  = user.activities.present? ? user.activities.map{|act| act.id} : []
          acts = []
          my_acts.each do |act|
            acts << act if act.weeks.include? wday  
          end
          activities = acts.map{|act|{id:act.id.to_s,name:act.name,category:act.categories_str,venue:act.merchant_name,city:act.full_city,pricing:act.get_price,img_url:act.first_img,like:true, details:act.details(my_act_ids), activity_state:act.activity_state, activity_public:act.activity_public, user_role: act.user.try(:role), first_name:act.user.try(:first_name), last_name:act.user.try(:last_name)}}
          
          sh = user.search_histories.where(search_name: params[:day], search_type: SearchHistory::SEARCH_TYPE[2], search_option: SearchHistory::SEARCH_OPTIONS[0]).first
          if sh.present?
            count = sh.search_count.to_i + 1
            sh.update_attribute(:search_count, count)
          else
            sh = user.search_histories.build(search_name: params[:day], search_type: SearchHistory::SEARCH_TYPE[2], search_option: SearchHistory::SEARCH_OPTIONS[0], search_count: 0)
            sh.save
          end
          GoogleAnalytics.new.page('/api/v1/activities/my_activities_by_day', 'get my activities by day', user.id)
          {:success =>activities}
        else
          {:failure => "not exist this ueser "}
        end
      end

      # Get my activities by time
      # GET: /api/v1/activities/my_activities_by_time
      # PARAMS:
      #    token:         String *required
      #    pod_ids:       String *required 
      #    duration:      String optional   
      # RESULTS:
      #    activities by time
      get :my_activities_by_time do
        user = User.find_by_token params[:token]
        if user.present?
          pod_ids = params[:pod_ids].delete(" ").split(",")          
          my_acts  = user.available_activities
          my_act_ids  = user.activities.present? ? user.activities.map{|act| act.id} : []       
          all_acts = []
          pod_ids.each do |p_id|
            all_acts = all_acts | my_acts.where({:parts_of_day_ids => /.*#{p_id}*./})
          end          
          if all_acts.first.nil?
            {:failure => "cannot find this activities"}
          else
            activities = all_acts.acts.map{|act|{id:act.id.to_s,name:act.name,category:act.categories_str,venue:act.merchant_name,city:act.full_city,pricing:act.get_price,img_url:act.first_img,like:true, details:act.details(my_act_ids), activity_state:act.activity_state, activity_public:act.activity_public, user_role: act.user.try(:role), first_name:act.user.try(:first_name), last_name:act.user.try(:last_name)}}
            GoogleAnalytics.new.page('/api/v1/activities/my_activities_by_time', 'get my activities by time', user.id)
            {success: activities}
          end
        else
          {:failure => "not exist this ueser "}
        end
      end

      # Get my preference activities
      # GET: /api/v1/activities/my_preference_activities
      # PARAMS:
      #    token:         String *required
      #    page:          Integer( page number )
      # RESULTS:
      #    get my activities
      get :my_preference_activities do
        user = User.find_by_token params[:token]        
        if user.present?

          acts = user.preference_activities.paginate(page: params[:page], :per_page => Activity::ACTIVITY_PAGE_LIMIT)
          my_act_ids  = user.activities.present? ? user.activities.map{|act| act.id} : []
          if acts.first.nil?
            {:failure => "not exist my activities"}  
          else
            activities = acts.map{|act|{id:act.id.to_s,name:act.name,category:act.categories_str,venue:act.merchant_name,city:act.full_city,pricing:act.get_price,img_url:act.first_img,like:true, details:act.details(my_act_ids), user_role: act.user.try(:role), first_name:act.user.try(:first_name), last_name:act.user.try(:last_name)}}
            GoogleAnalytics.new.page('/api/v1/activities/my_preference_activities', 'get my preference activities', user.id)
            {success: activities}
          end
        else
          {:failure => "not exist this ueser "}
        end
      end


      # Get contact preference activities
      # GET: /api/v1/activities/contact_preference_activities
      # PARAMS:
      #     token:          String *required
      #     contact_id:     String *required
      # RESULTS:
      #    get contact activities
      get :contact_preference_activities do
        user = User.find_by_token params[:token]        
        if user.present?
          contact = user.contacts.find(params[:contact_id])
          if contact.present?
            my_act_ids  = user.activities.present? ? user.activities.map{|act| act.id} : []
            acts = contact.preference_activities
            if acts.first.nil?
              {:failure => "not exist contact activities"}  
            else
              activities = acts.map{|act|{id:act.id.to_s,name:act.name,category:act.categories_str,venue:act.merchant_name,city:act.full_city,pricing:act.get_price,img_url:act.first_img,like:my_act_ids.include?(act.id), details:act.details(my_act_ids), user_role: act.user.try(:role), first_name:act.user.try(:first_name), last_name:act.user.try(:last_name)}}
              GoogleAnalytics.new.page('/api/v1/activities/contact_preference_activities', 'get contact preference activities', user.id)
              {success: activities}
            end
          else
            {failure: 'cannot find the contact'}
          end          
        else
          {:failure => "not exist this ueser "}
        end
      end

      # Filter based on contact and user's interests activities
      # GET: /api/v1/activities/user_and_contact_preference_activities
      # PARAMS:
      #     token:          String *required
      #     contact_id:     String *required
      # RESULTS:
      #    get contact activities      
      get :user_and_contact_preference_activities do
        user = User.find_by_token params[:token]        
        if user.present?
          contact = user.contacts.find(params[:contact_id])
          if contact.present?            
            my_act_ids  = user.activities.present? ? user.activities.map{|act| act.id} : []
            contact_acts = contact.preference_activities
            my_acts = user.preference_activities
            all_acts = my_acts | contact_acts
            
            if acts.first.nil?
              {:failure => "not exist contact activities"}  
            else
              activities = all_acts.map{|act|{id:act.id.to_s,name:act.name,category:act.categories_str,venue:act.merchant_name,city:act.full_city,pricing:act.get_price,img_url:act.first_img,like:my_act_ids.include?(act.id), details:act.details(my_act_ids), user_role: act.user.try(:role), first_name:act.user.try(:first_name), last_name:act.user.try(:last_name)}}
              GoogleAnalytics.new.page('/api/v1/activities/user_and_contact_preference_activities', 'get user and contact preference activities', user.id)
              {success: activities}
            end
          else
            {failure: 'cannot find the contact'}
          end          
        else
          {:failure => "not exist this ueser "}
        end
      end


      # Share activity
      # POST: /api/v1/activities/share
      # PARAMS:
      #     token:          String *required
      #     activity_id:     String *required
      # RESULTS:
      #    success string
      post :share do
        user = User.find_by_token params[:token]        
        if user.present?
          activity = Activity.where(id:params[:activity_id]).first
          if activity.nil?
            {:failure => "cannot find activity"}  
          else
            Activity.set_shared_count(user,activity)
            {success: "Successfully shared activity"}
          end
        else
          {:failure => "not exist this ueser "}
        end
      end

      # Call Merchant
      # POST: /api/v1/activities/call_merchant
      # PARAMS:
      #     token:            String *required
      #     activity_id:      String *required
      # RESULTS:
      #    success string
      post :call_merchant do
        user = User.find_by_token params[:token]        
        if user.present?
          activity = Activity.where(id:params[:activity_id]).first
          if activity.nil?
            {:failure => "cannot find activity"}  
          else
            Activity.set_checked_count(user,activity)
            {success: "successfully called"}
          end
        else
          {:failure => "not exist this ueser "}
        end
      end


      # Get facebook share image 
      # GET: /api/v1/activities/activity_share_image
      # PARAMS:
      #     activity_id:      String *required
      # RESULTS:
      #    success: image_url
      get :activity_share_image do
        activity = Activity.where(id:params[:activity_id]).first
        if activity.present?

          {success: activity.second_img}
          
        else
          {:failure => "cannot find activity second image"}
        end
      end

      # Upload Activity photo
      # POST: /api/v1/activities/upload_photo
      # PARAMS:
      #    token:       String *required
      #    activity_id: String *required
      #    photo:       Image  *required
      # RESULTS:
      #    gallery json object
      post :upload_photo do
        user = User.find_by_token params[:token]
        if user.present?
          activity = Activity.where(id: params[:activity_id]).first
          {:failure => "please select photo"} if params[:photo].nil?
          
          if activity.nil?
            {:failure => "not exist this activity"}  
          else
            logo = activity.logos.build(logo:params[:photo],user:user,state:Logo::STATE[0])
            if logo.save
              activity.update_attribute(:check_state, Activity::CHECK_STATE[0])
              gallery = activity.gallery_images(user).map{|l| {id:l.id.to_s,img_url:l.img_url,state:l.state,views:l.viewed_count}}
              {success: gallery}
            else
              {failure:logo.errors.messages}
            end
          end
        else
          {:failure => "not exist this ueser "}
        end
      end

      # Delete Activity photo
      # DELETE: /api/v1/activities/photo
      # PARAMS:
      #    token:       String *required
      #    photo_id:    String *required
      # RESULTS:
      #    success string
      delete :photo do
        user = User.find_by_token params[:token]
        if user.present?
          photo = user.upload_photos.where(id: params[:photo_id]).first
          if photo.nil?
            {:failure => "cannot find this photo"}  
          else
            if photo.user == user
              if photo.destroy
                {success: "deleted"}
              else
                {failure:photo.errors.messages}
              end
            else
              {failure: "you cannot delete this photo"}
            end
          end
        else
          {:failure => "not exist this ueser "}
        end
      end

      # Increase view count
      # POST: /api/v1/activities/photo_view
      # PARAMS:
      #    token:       String *required
      #    photo_id:    String *required      
      # RESULTS:
      #    success string      
      post :photo_view do
        user = User.find_by_token params[:token]
        if user.present?
          photo = Logo.where(id: params[:photo_id]).first
          if photo.nil?
            {:failure => "cannot find this photo"}  
          else            
            if photo.update_attribute(:viewed_count, photo.viewed_count+1)
              {success: "viewed"}
            else
              {failure:photo.errors.messages}
            end
          end
        else
          {:failure => "not exist this ueser "}
        end
      end

      # ******************* Activity manage ************************
      # Create Activity
      # POST: /api/v1/activities/activity
      # PARAMS:
      #     token:            String *required
      # ------- merchant info ------- 
      #     id:               String *required merchant id (from /api/v1/activities/yelp_search)
      #     yelp_name:        String
      #     yelp_categories:  String
      #     yelp_url          String
      #     address1          String
      #     address2          String
      #     country           String
      #     city              String
      #     state             String
      #     zip_code          String
      #     url               String
      # -------     end     -------
      #     name:             String *required
      #     description:      String
      #     parts_of_day_ids: String
      #     category_id:      String
      #     cost_id:          String
      #     level_id:         String
      #     attire_id:        String
      #     timeframe_ids:    String
      #     best_days:        String
      #     activity_public:   Boolean
      #     oryginal_photo    Image Data
      #     cover_photo:      Image Data
      #     thumb_photo:      Image Data
      #     cover_coordinates String
      #     thumb_coordinates String
      # RESULTS:
      #    success string
      post :activity do
        user = User.find_by_token params[:token]
        if user.present?
          @activity = Activity.new
          @activity.user = user
          merchant = Merchant.find_by_yelp_id(params[:id])
          if merchant.present?
            @activity.merchant = merchant
          else
            yelp_id = params[:id]
            yelp_client  = Yelp::Client.new
            yelp_request = Id.new(yelp_business_id:"#{yelp_id}",
                                  consumer_secret:'2bGhLN4subA3Sb4OC3a1G0vADzE',
                                  consumer_key:'ghQXcBzsrgvvjisFmWCb9A',
                                  token:'dJL24Rn1Q2wBXh2Tez71dKjh1pPhQc4T',
                                  token_secret:'J4_0qr35qUAoSo2VxH8MjKjWHig')
            yelp_response = yelp_client.search(yelp_request)
            if yelp_response.present?
              merchant = Merchant.new(name:yelp_response['name'], 
                address1:yelp_response['location']['address'].first, 
                address2:yelp_response['location']['address'].last, 
                country:yelp_response['location']['country_code'], 
                city:yelp_response['location']['city'], 
                state:yelp_response['location']['state_code'], 
                zip_code:yelp_response['location']['postal_code'],
                yelp_id:yelp_id, 
                yelp_name:yelp_response['name'], 
                yelp_categories:yelp_response['categories'], 
                url:yelp_response['url'])
              if merchant.save
                @activity.merchant = merchant
              else
                return {:failure => merchant.errors.messages}
              end
            else
              return {:failure => merchant.errors.messages}
            end
          end
          activity_public    = params[:activity_public] == 'true' ? true : false
          name              = params[:name]
          description       = params[:description]
          
          parts_of_day_ids  = params[:parts_of_day_ids]
          category_id       = params[:category_id]
          cost_id           = params[:cost_id]
          level_id          = params[:level_id]
          attire_id         = params[:attire_id]        
          timeframe_ids     = params[:timeframe_ids]
          best_days         = params[:best_days]
          cover_coordinates     = params[:cover_coordinates]
          thumb_coordinates     = params[:thumb_coordinates]
           
          category_id = "53c8e6af3537610002000000" if category_id == ""
          level_id = "53c8e7a73537610002010000" if level_id == ""
          attire_id = "53c8e8da3537610002020000," if attire_id == ""
          timeframe_ids = "53c8e9033537610002030000" if timeframe_ids == ""
          parts_of_day_ids = "53c8e9433537610002040000" if parts_of_day_ids == ""

          @activity.assign_attributes(name:name, 
            description:description, 
            parts_of_day_ids:parts_of_day_ids, 
            category_ids:category_id, 
            cost_ids:cost_id, 
            level_ids:level_id,
            attire_id:attire_id,
            timeframe_ids:timeframe_ids,
            best_days:best_days,
            activity_public:activity_public,
            cover_coordinates: cover_coordinates,
            thumb_coordinates: thumb_coordinates)

          if params[:oryginal_photo].present?
            st_logo = @activity.logos.build(logo:params[:oryginal_photo])
          end

          if params[:cover_photo].present?
            st_logo = @activity.logos.build(logo:params[:cover_photo])
          end

          if params[:thumb_photo].present?
            nd_logo = @activity.logos.build(logo:params[:thumb_photo])
          end

          img_ids = []
          if @activity.save
            st_logo.save if st_logo
            nd_logo.save if nd_logo
            img_ids[0]=st_logo.present? ? st_logo.id.to_s : ''
            img_ids[1]=nd_logo.present? ? nd_logo.id.to_s : ''            
            @activity.update_attribute(:image_ids, img_ids.join(","))
            {success: "Activity created successfully", activity_id: "#{@activity.id}"}
          else
            {failure: @activity.errors.messages}
          end
        else
          {:failure => "cannot find user"}
        end
      end

      # Yelp Search
      # GET: /api/v1/activities/yelp_search
      # PARAMS:
      #     term:            String *required
      #     location:        String *required


      # RESULTS:
      #    success string
      get :yelp_search do
        if (params[:location].present? && params[:term].present?)
          location = params[:location] #location = "Santa Clara"
          term = params[:term] #term = "Coffee"
          
          consumer_key = 'ghQXcBzsrgvvjisFmWCb9A'
          consumer_secret = '2bGhLN4subA3Sb4OC3a1G0vADzE'
          token = 'dJL24Rn1Q2wBXh2Tez71dKjh1pPhQc4T'
          token_secret = 'J4_0qr35qUAoSo2VxH8MjKjWHig'
          api_host = 'api.yelp.com'
          consumer = OAuth::Consumer.new(consumer_key, consumer_secret, {:site => "http://#{api_host}"})
          access_token = OAuth::AccessToken.new(consumer, token, token_secret)
          path = "/v2/search?&location=#{location}&term=#{term}"
          yelp_response = access_token.get(URI.escape(path)).body
          response = JSON.parse(yelp_response)
          businesses = response["businesses"]

          yelp_search = businesses.map{|business|{name:business['name'], address:business['location']['address'], id:business['url'].gsub("http://www.yelp.com/biz/","")}}
          {success: yelp_search}
        else
          {failure: "'term' and 'location' are required for search"}
        end
      end

      # Edit Activity
      # PUT: /api/v1/activities/activity
      # PARAMS:
      #     token:            String *required
      #     activity_id:      String *required
      #     name:             String *required
      #     description:      String
      #     parts_of_day_ids: String
      #     category_id:      String
      #     cost_id:          String *required
      #     level_id:         String
      #     attire_id:        String
      #     timeframe_ids:    String
      #     best_days:        String
      #     activity_public:   Boolean
      #     cover_photo:      Image Data
      #     thumb_photo:      Image Data

      # RESULTS:
      #    success string
      put :activity do
        user = User.find_by_token params[:token]
        if user.present?
          @activity = Activity.find(params[:activity_id])          
          
          activity_public    = params[:activity_public] == 'true' ? true : false
          name              = params[:name]
          description       = params[:description]
          
          parts_of_day_ids  = params[:parts_of_day_ids]
          category_id       = params[:category_id]
          cost_id           = params[:cost_id]
          level_id          = params[:level_id]
          attire_id         = params[:attire_id]        
          timeframe_ids     = params[:timeframe_ids]
          best_days         = params[:best_days]

          @activity.assign_attributes(name:name, 
            description:description, 
            parts_of_day_ids:parts_of_day_ids, 
            category_ids:category_id, 
            cost_ids:cost_id, 
            level_ids:level_id,
            attire_id:attire_id,
            timeframe_ids:timeframe_ids,
            best_days:best_days,
            last_update_user_id:user.id.to_s,
            activity_public:activity_public)

          if params[:cover_photo].present?
            st_logo = @activity.logos.build(logo:params[:cover_photo])
          end

          if params[:thumb_photo].present?
            nd_logo = @activity.logos.build(logo:params[:thumb_photo])
          end

          img_ids = []
          if @activity.save
            st_logo.save if st_logo
            nd_logo.save if nd_logo
            img_ids[0]=st_logo.present? ? st_logo.id.to_s : ''
            img_ids[1]=nd_logo.present? ? nd_logo.id.to_s : ''            
            @activity.update_attribute(:image_ids, img_ids.join(","))
            {success: "Activity created successfully"}
          else
            {failure: @activity.errors.messages}
          end
        else
          {:failure => "cannot find user"}
        end
      end

      # Delete Activity
      # DELETE: /api/v1/activities/activity
      # PARAMS:
      #     token:            String *required
      #     activity_id:      String *required
      # RESULTS:
      #    success string
      delete :activity do
        user = User.find_by_token params[:token]
        if user.present?
          activity = Activity.where(id: params[:activity_id]).first
          if activity.nil?
            {:failure => "cannot find your activity"}  
          else            
            if activity.destroy
              {success: "successfully deleted"}
            else
              {failure: activity.errors.messages}
            end
          end
        else
          {:failure => "cannot find user"}
        end
      end

      # Get Best days
      # GET: /api/v1/activities/best_days
      # PARAMS:
      #   
      # RESULTS:
      #   Get best days array
      get :best_days do
        {success: Activity::BEST_DAYS.map{|bd| [bd,Activity::BEST_DAYS.index(bd)]}}
      end

      # Get All Attires
      # GET: /api/v1/activities/attires
      # PARAMS:
      #   
      # RESULTS:
      #   Get attires list
      get :attires do
        all_attires = Attire.where(:active => true).order_by('order_id ASC')
        attires = all_attires.map{|attire| {id:attire.id.to_s,name:attire.name,default_img:attire.default_img_url,selected_img:attire.selected_img_url,thumb_img:attire.thumb_img_url}}
        {success:attires}
      end

      # Get All Best Time of Days
      # GET: /api/v1/activities/best_time_of_days
      # PARAMS:
      #   
      # RESULTS:
      #   Get Best Time of days list
      get :best_time_of_days do
        all_p_of_days = PartsOfDay.where(:active => true).order_by('order_id ASC')
        p_of_days = all_p_of_days.map{|p| {id:p.id.to_s,name:p.name}}
        {success:p_of_days}
      end

      # Get All Durations
      # GET: /api/v1/activities/durations
      # PARAMS:
      #   
      # RESULTS:
      #   Get Best Time of days list
      get :durations do
        all_durations = Timeframe.where(:active => true).order_by('order_id ASC')
        durations = all_durations.map{|d| {id:d.id.to_s,name:d.name}}
        {success:durations}
      end


    end
  end
end