module Endpoints
  class Dates < Grape::API

    resource :dates do
      # Ping
      # GET: /api/v1/dates/ping
      # PARAMS:
      #   
      # RESULTS:
      #   gwangming dates
      get :ping do
        { :ping => 'gwangming dates' }
      end
      
      # Get date types
      # GET: /api/v1/dates/date_types
      #
      # RESULTS:
      #   get date types
      get :date_types do
        date_types = DateType.where(active: true).order_by('order_id ASC')
        if date_types.first.nil?
          {failure: "not exists date types"}
        else
          {success: date_types.map{|dt| {id:dt.id.to_s,name:dt.name}}}
        end
      end
      
      # Get activity
      # GET: /api/v1/dates/activity
      #
      # RESULTS:
      #   get activity json object
      get :activity do
        user = User.find_by_token params[:token]
        if user.present?
          acts = Activity.where(id: params[:activity_id])
          if acts.first.nil?
            {:failure => "not exist this activity"}  
          else
            activities = acts.map{|act|{id:act.id.to_s,name:act.name,category:act.categories_str,venue:act.merchant_name,city:act.full_city,pricing:act.get_price,img_url:act.first_img,himg_url:act.second_img}}
            GoogleAnalytics.new.event('date', 'get activity', user.name, user.id)
            {success:activities}
          end
        else
          {:failure => "not exist this ueser "}
        end
      end

      # Get my dates
      # GET: /api/v1/dates/dates
      # PARAMS:
      #    token:         String *required
      #    page:          Integer( page number )
      # RESULTS:
      #    get my dates json object
      get :dates do
        user = User.find_by_token params[:token]
        if user.present?
          dates = user.my_actived_dates.order_by('created_at DESC').paginate(page: params[:page], :per_page => MyDate::DATE_PAGE_LIMIT)
          if dates.first.nil?
            {:failure => "not exist my dates"}  
          else
            my_dates = dates.map{|dt|{date_type:dt.date_type_name,id:dt.id.to_s,name:dt.name,contact:dt.contact_name, img:dt.img, price:dt.price, city:dt.date_location, st_date:dt.st_date.present? ? dt.st_date.strftime("%m/%d/%Y,%I:%M %p") : '', ed_date:dt.ed_date.present? ? dt.ed_date.strftime("%m/%d/%Y,%I:%M %p") : '', category:dt.category, anchor_id:dt.anchor_activity.present? ? dt.anchor_activity.id.to_s : ''}}
            GoogleAnalytics.new.event('date', 'get dates', user.name, user.id)
            {success:my_dates}
          end
        else
          {:failure => "not exist this ueser "}
        end
      end

      # Get my dates
      # GET: /api/v1/dates/get_date_item
      # PARAMS:
      #    token:         String *required
      #    date_id:       String *required      
      # RESULTS:
      #    get my dates json object
      get :get_date_item do
        user = User.find_by_token params[:token]
        if user.present?
          dt = MyDate.where(id:params[:date_id]).first
          if dt.present?
            date_item = {date_type:dt.date_type_name,
            id:dt.id.to_s,
            name:dt.name,
            contact:dt.contact_name, 
            img:dt.img, 
            price:dt.price, 
            city:dt.date_location, 
            date_time:dt.date_time, 
            category:dt.category, 
            activity_names:dt.activity_names, 
            activity_locations:dt.activity_locations, 
            anchor_id:dt.anchor_activity.present? ? dt.anchor_activity.id.to_s : ''}
            {success:date_item}
          else
            {:failure => "cannot find this date"}
          end
        else
          {:failure => "cannot find user"}
        end
      end


      # Get my date detail
      # GET: /api/v1/dates/date
      # PARAMS:
      #    token:         String *required
      #    date_id:       Integer( page number )
      # RESULTS:
      #    get my date detail
      
      get :date do
        user = User.find_by_token params[:token]
        if user.present?
          date = user.my_dates.where(id:params[:date_id]).first
          if date.nil?
            {:failure => "cannot find this date"}
          else
            GoogleAnalytics.new.event('date', 'get date details', user.name, user.id)
            {success:date.details(user)}
          end
        else
          {:failure => "not exist this ueser "}
        end
      end

      # Get featured dates
      # GET: /api/v1/dates/featured_dates
      # PARAMS:
      #    token:         String *required
      #    page:          Integer( page number )
      # RESULTS:
      #    get featured dates json object
      
      get :featured_dates do 
        user = User.find_by_token params[:token]
        if user.present?          
          dates = MyDate.all_users_suggested_dates.order_by('created_at DESC').paginate(page: params[:page], :per_page => MyDate::DATE_PAGE_LIMIT)
          MyDate.set_browsed_count(user, dates)          
          if dates.first.nil?
            {:failure => "not exist featured dates"}  
          else
            f_dates = dates.map{|dt|{date_type:dt.date_type_name,id:dt.id.to_s,name:dt.name,contact:dt.contact_name, img:dt.img, price:dt.price, city:dt.date_location, st_date:dt.st_date.present? ? dt.st_date.strftime("%m/%d/%Y,%I:%M %p") : '', ed_date:dt.ed_date.present? ? dt.ed_date.strftime("%m/%d/%Y,%I:%M %p") : '', category:dt.category, anchor_id:dt.anchor_activity.present? ? dt.anchor_activity.id.to_s : ''}}
            GoogleAnalytics.new.event('date', 'get featured dates', user.name, user.id)
            {success:f_dates}
          end
        else
          {:failure => "not exist this ueser "}
        end
      end
      
      # Get featured date detail
      # GET: /api/v1/dates/featured_date
      # PARAMS:
      #    token:                   String *required
      #    featured_date_id:        Integer( page number )
      # RESULTS:
      #    get featured date detail
      get :featured_date do 
        user = User.find_by_token params[:token]
        if user.present?
          date = MyDate.all_users_suggested_dates.where(id:params[:featured_date_id]).first
          if date.nil?
            {:failure => "cannot find this featured date"}
          else
            GoogleAnalytics.new.event('date', 'get featured date details', user.name, user.id)
            {success:date.details(user)}
          end
        else
          {:failure => "not exist this ueser "}
        end
      end

      # Create new date
      # POST: /api/v1/dates/create

      # parameters accepted
      #  'token'             String, *required
      #  'anchor_id'         String
      #  'date_type_id'      String
      #  'contact_id'        String
      #  'st_date'           String  "05/25/2014,18"
      #  'ed_date'           String  "05/25/2014,18"
      #  'featured_id'       String
      #  'activity_ids'      String
      #  'date_state'        String
      #  'date_private'      Boolean  
      post :create do
        user = User.find_by_token params[:token]
        date_type     = params[:date_type_id]
        contact_id     = params[:contact_id]
        anchor_id      = params[:anchor_id]
        st_date = params[:st_date].present? ? DateTime.strptime(params[:st_date], "%m/%d/%Y,%H:%M").to_s : nil
        ed_date = params[:ed_date].present? ? DateTime.strptime(params[:ed_date], "%m/%d/%Y,%H:%M").to_s : nil
        ct_ids        = []
        tf_ids        = []
        lv_ids        = []
        pd_ids        = []

        featured_id   = params[:featured_id]
        activity_ids  = params[:activity_ids].delete(" ") if params[:activity_ids].present?

        best_days     = Activity.all_best_days(activity_ids.split(',')).join(',') if activity_ids.present?
        
        

        if params[:activity_ids].present?
          acts = Activity.find(params[:activity_ids].split(","))
          acts.each do |act|
            ct_ids = ct_ids | act.category_ids.split(",")
            tf_ids = tf_ids | act.timeframe_ids.split(",")
            lv_ids = lv_ids | act.level_ids.split(",")
            pd_ids = pd_ids | act.parts_of_day_ids.split(",")
          end
        end
        if user.present?
          if featured_id.present?
            f_date = MyDate.find(featured_id)
            f_date.add_user(user.id.to_s)
          end
          
          if anchor_id.present?
            af = Activity.where(id:anchor_id).first
            loc = af.present? ? af.location.id.to_s : ''
          else
            af = Activity.in(id:activity_ids.present? ? activity_ids.split(',') : '').first
            loc = af.present? ? af.location.id.to_s : ''
          end
          
          date = user.my_dates.build(
            anchor_id:anchor_id,
            contact_id:contact_id, 
            date_type_id:date_type, 
            st_date:st_date, 
            ed_date:ed_date, 
            featured_id:featured_id, 
            activity_ids:activity_ids, 
            parts_of_day_ids:pd_ids.join(","),
            category_ids:ct_ids.join(","),
            timeframe_ids:tf_ids.join(","),
            level_ids:lv_ids.join(","), 
            location:loc,
            user_type:user.type,
            active:true,
            date_state:'3',
            :private => true,
            best_days:best_days
            )
          if date.save
            contact = Contact.where(id:params[:contact_id]).first
            if contact.present?
              contact.update_attributes(contacted_date:date.st_date)
            end

            MyDate.set_created_count(user, date)
            GoogleAnalytics.new.event('date', 'create new date', user.name, user.id)
            {success: date.id.to_s}
          else
            {:failure => "cannot create this date"}
          end
        else
          {:failure => "not exist this ueser "}
        end
      end

      post :update do
        user = User.find_by_token params[:token]
        anchor_id     = params[:anchor_id]
        date_id       = params[:date_id]
        date_type     = params[:date_type_id]
        contact       = params[:contact_id]
        st_date       = DateTime.strptime(params[:st_date], "%m/%d/%Y,%H:%M").to_s
        ed_date       = DateTime.strptime(params[:ed_date], "%m/%d/%Y,%H:%M").to_s
        activity_ids  = params[:activity_ids].delete(" ") if params[:activity_ids].present?
        ct_ids        = []
        tf_ids        = []
        lv_ids        = []
        pd_ids        = []

        pod_ids =''
        if params[:activity_ids].present?
          acts = Activity.find(params[:activity_ids].split(","))
          acts.each do |act|
            ct_ids = ct_ids | act.category_ids.split(",")
            tf_ids = tf_ids | act.timeframe_ids.split(",")
            lv_ids = lv_ids | act.level_ids.split(",")
            pd_ids = pd_ids | act.parts_of_day_ids.split(",")
          end
        end
        date_state    = params[:date_state]
        date_private  = params[:date_private] == 'true' ? true : false
        best_days     = Activity.all_best_days(activity_ids.split(',')).join(',') if activity_ids.present?

        if user.present?          
          date = user.my_dates.where(id:date_id).first
          return {:failure => "cannot find this date from your dates"} if date.nil?
          duration = Activity.duration(activity_ids.split(","))

          if anchor_id.present?
            af = Activity.where(id:anchor_id).first
            loc = af.present? ? af.location.id.to_s : ''
          else
            af = Activity.in(id:activity_ids.present? ? activity_ids.split(',') : '').first
            loc = af.present? ? af.location.id.to_s : ''
          end
          
          date.assign_attributes(
            anchor_id: anchor_id, 
            activity_ids: activity_ids, 
            contact_id: contact, 
            date_type_id: date_type, 
            st_date:st_date, 
            ed_date:ed_date, 
            parts_of_day_ids:pd_ids.join(","),
            category_ids:ct_ids.join(","),
            timeframe_ids:tf_ids.join(","),
            level_ids:lv_ids.join(","), 
            date_duration: duration, 
            location:loc,
            user_type:user.type,
            date_state:date_state,
            :private => date_private,
            best_days:best_days
            )

          if date.save
            GoogleAnalytics.new.event('date', 'update date', user.name, user.id)
            {success: "updated successfully"}
          else
            {:failure => "cannot update this date"}
          end
        else
          {:failure => "not exist this ueser "}
        end
      end

      post :delete do
        user = User.find_by_token params[:token]
        date_id       = params[:date_id]
        if user.present?
          date = user.my_dates.find(date_id)        
          if date.destroy
            GoogleAnalytics.new.event('date', 'delete date', user.name, user.id)
            {success: "deleted successfully"}
          else
            {:failure => "cannot delete this date"}
          end
        else
          {:failure => "not exist this ueser "}
        end
      end

      post :add_activity do
        user = User.find_by_token params[:token]
        date_id       = params[:date_id]        
        activity_id   = params[:activity_id]
        ct_ids        = []
        tf_ids        = []
        lv_ids        = []
        pd_ids        = []

        activity = Activity.where(id:activity_id).first
        return {failure: "cannot find activity"} if activity.nil?

        if user.present?
          date = user.my_dates.where(id:date_id).first
          return {success: "cannot find date"} if date.blank?
          activity_ids = []          
          activity_ids = date.activity_ids.split(",") if date.activity_ids.present?
          activity_ids << activity_id
          
          acts = Activity.find(activity_ids)
          acts.each do |act|
            ct_ids = ct_ids | act.category_ids.split(",")
            tf_ids = tf_ids | act.timeframe_ids.split(",")
            lv_ids = lv_ids | act.level_ids.split(",")
            pd_ids = pd_ids | act.parts_of_day_ids.split(",")
          end

          if date.update_attributes(activity_ids:activity_ids.join(","),parts_of_day_ids:pd_ids.join(","),category_ids:ct_ids.join(","),timeframe_ids:tf_ids.join(","),level_ids:lv_ids.join(","))
            Activity.set_added_count(user, activity)
            GoogleAnalytics.new.event('date', 'add activity to date', user.name, user.id)
            {success: "added activity"}
          else
            {:failure => "cannot add activity"}
          end
        else
          {:failure => "not exist this ueser "}
        end
      end

      post :delete_activity do
        user = User.find_by_token params[:token]
        date_id       = params[:date_id]        
        activity_id   = params[:activity_id]
        
        activity = Activity.where(id:activity_id).first
        return {failure: "cannot find activity"} if activity.nil?

        if user.present?
          date = user.my_dates.where(id:date_id).first
          return {success: "cannot find date"} if date.blank?
          activity_ids = []
          activity_ids = date.activity_ids.split(",") if date.activity_ids.present?
          activity_ids.delete(activity_id)
          if date.update_attribute(:activity_ids, activity_ids.join(","))
            activity.update_attribute(:added_count,activity.added_count.to_i-1)
            GoogleAnalytics.new.event('date', 'delete activity from date', user.name, user.id)
            {success: "deleted activity"}
          else
            {:failure => "cannot add activity"}
          end
        else
          {:failure => "not exist this ueser "}
        end
      end

      post :delete do
        user = User.find_by_token params[:token]
        if user.present?
          date = user.my_dates.where(id:date_id).first
          if date.blank?
            {:failure => "cannot find this date"}
          else            
            date.destroy
            GoogleAnalytics.new.event('date', 'delete date', user.name, user.id)
            {success: "deleted this date"}
          end
        else
          {:failure => "not exist this ueser "}
        end
      end


      # Sharing date
      # POST: /api/v1/dates/share
      # PARAMS:
      #    token:     String, *required
      #    date_id:   String, *required
      #    share_type String, [social, community]

      post :share do
        user = User.find_by_token params[:token]
        share_type = params[:share_type]
        if user.present?          
          date = user.my_dates.where(id:params[:date_id]).first
          if date.nil?
            {:failure => "cannot find this date"}
          else
            MyDate.set_shared_count(user, date, share_type)
            GoogleAnalytics.new.event('date', 'share date', user.name, user.id)
            {success: "shared this date"}
          end
        else
          {:failure => "not exist this ueser "}
        end
      end

      # Get featured dates by multi filtering
      # GET: /api/v1/dates/featured_dates_by_multi_filter
      # PARAMS:
      #    token:       String, *required
      #    location:    String, default value is current location
      #    datetype:    String(array), default value is all
      #    day:         String, default value is any
      #    wday:        String(array) 
      #    pod_ids:     String(array), defalut value is any
      #    durations:   String(array)
      #    page:        Integer( page number )
      # RESULTS:
      #    activities JSON data
      get :featured_dates_by_multi_filter do
        
        if params[:location].split(',').count > 2 
          city_name = params[:location].split(',')[1].strip
        else
          city_name = params[:location].split(',').first
        end        
        location = Location.where({:name => /^#{city_name.strip}$/i}).first
        
        user = User.find_by_token params[:token]

        if user.present?                    
          # dates by location
          location_dates = location.my_dates.all_users_suggested_dates if location.present?

          # dates by datetype
          if params[:datetype] == 'all'
            date_type_dates = MyDate.all_users_suggested_dates
          else
            date_type_ids = params[:datetype].split(',')
            date_type_dates = MyDate.all_users_suggested_dates.in(date_type_id: date_type_ids)
          end
          
          # dates by day or wday

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
            wday_dates = MyDate.all_users_suggested_dates.where({:best_days=>Regexp.new(".*"+wday.to_s+".*")})
          elsif params[:wday]
            w_dates = ""
            wdays = params[:wday].split(",")
            wdays.each do |w|
              date_ids = MyDate.all_users_suggested_dates.where({:best_days=>Regexp.new(".*"+w+".*")}).map{|a| a.id.to_s}
              w_dates = w_dates + date_ids.join(",") + ","
            end
            w_dates.chop!
            wday_dates = MyDate.all_users_suggested_dates.in(id:w_dates.split(","))
          end

          # parts of day or duration
          date_ids = location_dates.present? ? location_dates.map(&:id) : []

          if date_type_dates.present?
            if date_ids.present?
              date_ids = date_ids & date_type_dates.map(&:id)
            else
              date_ids = date_type_dates.map(&:id)
            end
          end

          if wday_dates.present?
            if date_ids.present?
              date_ids = date_ids & wday_dates.map(&:id) 
            else
              date_ids = wday_dates.map(&:id) 
            end
          end

          dates = MyDate.all_users_suggested_dates.in(id:date_ids.uniq).order_by('created_at DESC').paginate(page: params[:page], :per_page => MyDate::DATE_PAGE_LIMIT)
          all_dates = dates.map{|dt| dt.detail}
          
          MyDate.set_browsed_count(user, dates)
          user.reports.create(location:params[:location],
                              datetype: params[:datetype],
                              day:params[:day],
                              time:params[:pod_ids],
                              type_of_search:Report::TYPE_OF_SEARCH[3],
                              results:dates.map{|d| d.id.to_s}.join(","))
            
          GoogleAnalytics.new.event('date', 'get dates by locatin', user.name, user.id)
          {:success => all_dates}
        else
          {:failure => "not exist this ueser "}
        end

      end

      # Get my dates by multi filtering
      # GET: /api/v1/dates/my_dates_by_multi_filter
      # PARAMS:
      #    token:     String, *required
      #    location:  String, default value is current location
      #    datetype:  String(array), default value is all
      #    day:       String, default value is any
      #    wday:      String(array) 
      #    pod_ids:   String(array), defalut value is any
      #    durations: String(array)
      #    page:      Integer( page number )
      # RESULTS:
      #    activities JSON data
      get :my_dates_by_multi_filter do
        
        user = User.find_by_token params[:token]        
        if user.present?
          user_dates = user.my_actived_dates
          if user_dates.blank?
            return  {failure: "cannot find my dates"}
          end
          # dates by location
          location = Location.where(:name=>params[:location]).first        
          location_dates = user_dates.in(location:location.id.to_s) if location.present?
                           
          # dates by datetype
          if params[:datetype] == 'all'
            date_type_dates = user_dates
          else
            date_type_ids = params[:datetype].split(',')
            date_type_dates = user_dates.in(date_type_id: date_type_ids)
          end
          
          # dates by day or wday
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
            wday_dates = user_dates.where({:best_days=>Regexp.new(".*"+wday.to_s+".*")})
          elsif params[:wday]
            w_dates = ""
            wdays = params[:wday].split(",")
            wdays.each do |w|
              date_ids = user_dates.where({:best_days=>Regexp.new(".*"+w+".*")}).map{|a| a.id.to_s}
              w_dates = w_dates + date_ids.join(",") + ","
            end
            w_dates.chop!
            wday_dates = user_dates.in(id:w_dates.split(","))
          end

          date_ids = location_dates.present? ? location_dates.map(&:id) : []

          if date_type_dates.present?
            if date_ids.present?
              date_ids = date_ids & date_type_dates.map(&:id)
            else
              date_ids = date_type_dates.map(&:id)
            end
          end

          if wday_dates.present?
            if date_ids.present?
              date_ids = date_ids & wday_dates.map(&:id) 
            else
              date_ids = wday_dates.map(&:id) 
            end
          end

          dates = user_dates.in(id:date_ids.uniq).order_by('created_at DESC').paginate(page: params[:page], :per_page => MyDate::DATE_PAGE_LIMIT)
          all_dates = dates.map{|dt| dt.detail}
          

          MyDate.set_browsed_count(user, dates)
          user.reports.create(location:params[:location],
                              datetype: params[:datetype],
                              day:params[:day],
                              time:params[:pod_ids],
                              type_of_search:Report::TYPE_OF_SEARCH[2],
                              results:dates.map{|d| d.id.to_s}.join(","))
          GoogleAnalytics.new.event('date', 'get dates by locatin', user.name, user.id)
          {:success => all_dates}
        else
          {:failure => "not exist this ueser "}
        end
      end

      # Get featured dates by location
      # GET: /api/v1/dates/dates_by_location
      # PARAMS:
      #    token:     String, *required
      #    location:  String, default value is current location
      #    page:      Integer( page number )
      # RESULTS:
      #    mydates JSON data
      get :dates_by_location do
        return {:failure => "please input location"} if params[:location].blank?
        location = Location.where(:name=>params[:location]).first
        user = User.find_by_token params[:token]        
        return {failure: "Cannot find location"} if location.blank?        
        if user.present?          
          dates = location.my_dates.all_users_suggested_dates.order_by('created_at DESC').paginate(page: params[:page], :per_page => MyDate::DATE_PAGE_LIMIT)
          my_dates = dates.map{|dt|{date_type:dt.date_type_name,id:dt.id.to_s,name:dt.name,contact:dt.contact_name, img:dt.img, price:dt.price, city:dt.date_location, date_time:dt.date_time, category:dt.category, activity_names:dt.activity_names, activity_locations:dt.activity_locations, anchor_id:dt.anchor_activity.present? ? dt.anchor_activity.id.to_s : ''}}
          sh = user.search_histories.where(search_name: params[:location], search_type: SearchHistory::SEARCH_TYPE[0], search_option: SearchHistory::SEARCH_OPTIONS[1]).first
          if sh.present?
            count = sh.search_count.to_i + 1
            sh.update_attribute(:search_count, count)
          else
            sh = user.search_histories.build(search_name: params[:location], search_type: SearchHistory::SEARCH_TYPE[0], search_option: SearchHistory::SEARCH_OPTIONS[1], search_count: 0)
            sh.save
          end
          MyDate.set_browsed_count(user, dates)
          GoogleAnalytics.new.event('date', 'get dates by locatin', user.name, user.id)
          {:success =>my_dates}
        else
          {:failure => "not exist this ueser "}
        end
      end

      # Get featured dates by date type
      # GET: /api/v1/dates/dates_by_location
      # PARAMS:
      #    token:         String, *required
      #    date_type_id:  String, default value is current location
      #    page:          Integer( page number )
      # RESULTS:
      #    mydates JSON data
      get :dates_by_date_type do
        return {:failure => "please select date type"} if params[:date_type_id].blank?
        user = User.find_by_token params[:token]
        if user.present?
          dates = MyDate.all_users_suggested_dates.where(date_type_id: params[:date_type_id]).order_by('created_at DESC').paginate(page: params[:page], :per_page => MyDate::DATE_PAGE_LIMIT)
          
          my_dates = dates.map{|dt|{date_type:dt.date_type_name,id:dt.id.to_s,name:dt.name,contact:dt.contact_name, img:dt.img, price:dt.price, city:dt.date_location, date_time:dt.date_time, category:dt.category, activity_names:dt.activity_names, activity_locations:dt.activity_locations, anchor_id:dt.anchor_activity.present? ? dt.anchor_activity.id.to_s : ''}}
          if dates.blank?
            {:failure => "cannot find this date"}
          else
            MyDate.set_browsed_count(user, dates)
            GoogleAnalytics.new.event('date', 'get dates by date type', user.name, user.id)
            {success: my_dates}
          end
        else
          {:failure => "not exist this ueser "}
        end
      end

      # Get featured dates by day
      # GET: /api/v1/dates/dates_by_location
      # PARAMS:
      #    token:         String, *required
      #    day:            String, default value is current location
      #    page:          Integer( page number )
      # RESULTS:
      #    mydates JSON data
      get :dates_by_day do
        return {:failure => "please input day"} if params[:day].blank?        
        user = User.find_by_token params[:token]        
        
        if user.present?
          st_dt = DateTime.strptime(params[:day],'%Y-%m-%d')
          ed_dt = DateTime.strptime(params[:day]+'-23','%Y-%m-%d-%H') 

          page_num = params[:offset].present? ? params[:offset] : 1
          dates = MyDate.all_users_suggested_dates.where(:st_date=>{:$lte=>ed_dt, :$gt => st_dt}).order_by('created_at DESC').paginate(page: params[:page], :per_page => MyDate::DATE_PAGE_LIMIT)
          my_dates = dates.map{|dt|{date_type:dt.date_type_name,id:dt.id.to_s,name:dt.name,contact:dt.contact_name, img:dt.img, price:dt.price, city:dt.date_location, date_time:dt.date_time, category:dt.category, activity_names:dt.activity_names, activity_locations:dt.activity_locations, anchor_id:dt.anchor_activity.present? ? dt.anchor_activity.id.to_s : ''}}

          sh = user.search_histories.where(search_name: params[:day], search_type: SearchHistory::SEARCH_TYPE[2], search_option: SearchHistory::SEARCH_OPTIONS[1]).first
          if sh.present?
            count = sh.search_count.to_i + 1
            sh.update_attribute(:search_count, count)
          else
            sh = user.search_histories.build(search_name: params[:day], search_type: SearchHistory::SEARCH_TYPE[2], search_option: SearchHistory::SEARCH_OPTIONS[1], search_count: 0)
            sh.save
          end
          GoogleAnalytics.new.event('date', 'get dates by day', user.name, user.id)
          MyDate.set_browsed_count(user, dates)
          {:success =>my_dates}
        else
          {:failure => "not exist this ueser "}
        end
      end
      
      get :dates_by_time do
        user = User.find_by_token params[:token]
        if user.present?
          pod_ids = params[:pod_ids].delete(" ").split(",")          
          dates = MyDate.all_users_suggested_dates          
          #pod_ids.each do |p_id|
          #  dates = dates.where({ :parts_of_day_ids => /.*#{p_id}*./ })  
          #end
          all_dates = []
          pod_ids.each do |p_id|
            all_dates = all_dates | dates.where({:parts_of_day_ids => /.*#{p_id}*./,:duration => params[:duration]})
          end          
          my_dates = all_dates.map{|dt|{date_type:dt.date_type_name,id:dt.id.to_s,name:dt.name,contact:dt.contact_name, img:dt.img, price:dt.price, city:dt.date_location, date_time:dt.date_time, category:dt.category, activity_names:dt.activity_names, activity_locations:dt.activity_locations, anchor_id:dt.anchor_activity.present? ? dt.anchor_activity.id.to_s : ''}}
          if dates.nil?
            {:failure => "cannot find this dates"}
          else
            MyDate.set_browsed_count(user, all_dates)
            GoogleAnalytics.new.event('date', 'get dates by time', user.name, user.id)
            {success: my_dates}
          end
        else
          {:failure => "not exist this ueser "}
        end
      end



      # Get my dates by location
      # GET: /api/v1/dates/dates_by_location
      # PARAMS:
      #    token:         String, *required
      #    location:      String
      #    page:          Integer( page number )
      # RESULTS:
      #    mydates JSON data
      get :my_dates_by_location do
        return {:failure => "please input location"} if params[:location].blank?
        location = Location.where(:name=>params[:location]).first
        user = User.find_by_token params[:token]        
        return {failure: "Cannot find location"} if location.blank?        
        if user.present?
          dates = user.my_dates.where({location_id:location.id}).order_by('created_at DESC').paginate(page: params[:page], :per_page => MyDate::DATE_PAGE_LIMIT)
          my_dates = dates.map{|dt|{date_type:dt.date_type_name,id:dt.id.to_s,name:dt.name,contact:dt.contact_name, img:dt.img, price:dt.price, city:dt.date_location, date_time:dt.date_time, category:dt.category, activity_names:dt.activity_names, activity_locations:dt.activity_locations, anchor_id:dt.anchor_activity.present? ? dt.anchor_activity.id.to_s : ''}}
          
          sh = user.search_histories.where(search_name: params[:location], search_type: SearchHistory::SEARCH_TYPE[0], search_option: SearchHistory::SEARCH_OPTIONS[1]).first
          if sh.present?
            count = sh.search_count.to_i + 1
            sh.update_attribute(:search_count, count)
          else
            sh = user.search_histories.build(search_name: params[:location], search_type: SearchHistory::SEARCH_TYPE[0], search_option: SearchHistory::SEARCH_OPTIONS[1], search_count: 0)
            sh.save
          end
          MyDate.set_browsed_count(user, all_dates)
          GoogleAnalytics.new.event('date', 'get my dates by location', user.name, user.id)
          {:success =>my_dates}
        else
          {:failure => "not exist this ueser "}
        end
      end

      # Get my dates by date type
      # GET: /api/v1/dates/dates_by_location
      # PARAMS:
      #    token:         String, *required
      #    date_type_id:  String
      #    page:          Integer( page number )
      # RESULTS:
      #    mydates JSON data
      get :my_dates_by_date_type do
        return {:failure => "please select date type"} if params[:date_type_id].blank?
        user = User.find_by_token params[:token]
        if user.present?
          page_num = params[:offset].present? ? params[:offset] : 1
          dates = user.my_dates.where(date_type_id: params[:date_type_id]).order_by('created_at DESC').paginate(page: params[:page], :per_page => MyDate::DATE_PAGE_LIMIT)
          my_dates = dates.map{|dt|{date_type:dt.date_type_name,id:dt.id.to_s,name:dt.name,contact:dt.contact_name, img:dt.img, price:dt.price, city:dt.date_location, date_time:dt.date_time, category:dt.category, activity_names:dt.activity_names, activity_locations:dt.activity_locations, anchor_id:dt.anchor_activity.present? ? dt.anchor_activity.id.to_s : ''}}
          
          if dates.blank?
            {:failure => "cannot find this date"}
          else
            MyDate.set_browsed_count(user, all_dates)
            GoogleAnalytics.new.event('date', 'get my dates by date type', user.name, user.id)
            {success: my_dates}
          end
        else
          {:failure => "not exist this ueser "}
        end
      end

      # Get my dates by date type
      # GET: /api/v1/dates/dates_by_location
      # PARAMS:
      #    token:         String, *required
      #    day:            String
      #    page:          Integer( page number )
      # RESULTS:
      #    mydates JSON data
      get :my_dates_by_day do
        return {:failure => "please input day"} if params[:day].blank?        
        user = User.find_by_token params[:token]        
        
        if user.present?          
          page_num = params[:offset].present? ? params[:offset] : 1
          dates = user.my_dates.where(dates_date:params[:day]).order_by('created_at DESC').paginate(page: params[:page], :per_page => MyDate::DATE_PAGE_LIMIT)
          my_dates = dates.map{|dt|{date_type:dt.date_type_name,id:dt.id.to_s,name:dt.name,contact:dt.contact_name, img:dt.img, price:dt.price, city:dt.date_location, date_time:dt.date_time, category:dt.category, activity_names:dt.activity_names, activity_locations:dt.activity_locations, anchor_id:dt.anchor_activity.present? ? dt.anchor_activity.id.to_s : ''}}

          sh = user.search_histories.where(search_name: params[:day], search_type: SearchHistory::SEARCH_TYPE[2], search_option: SearchHistory::SEARCH_OPTIONS[1]).first
          if sh.present?
            count = sh.search_count.to_i + 1
            sh.update_attribute(:search_count, count)
          else
            sh = user.search_histories.build(search_name: params[:day], search_type: SearchHistory::SEARCH_TYPE[2], search_option: SearchHistory::SEARCH_OPTIONS[1], search_count: 0)
            sh.save
          end
          MyDate.set_browsed_count(user, all_dates)
          GoogleAnalytics.new.event('date', 'get my dates by day', user.name, user.id)
          {:success =>my_dates}
        else
          {:failure => "not exist this ueser "}
        end
      end
      
      get :my_dates_by_time do
        user = User.find_by_token params[:token]
        if user.present?
          pod_ids = params[:pod_ids].delete(" ").split(",")          
          dates = user.my_dates          
          #pod_ids.each do |p_id|
          #  dates = dates.where({ :parts_of_day_ids => /.*#{p_id}*./ })  
          #end
          all_dates = []
          pod_ids.each do |p_id|
            all_dates = all_dates | dates.where({:parts_of_day_ids => /.*#{p_id}*./,:duration =>params[:duration]})
          end          
          my_dates = all_dates.map{|dt|{date_type:dt.date_type_name,id:dt.id.to_s,name:dt.name,contact:dt.contact_name, img:dt.img, price:dt.price, city:dt.date_location, date_time:dt.date_time, category:dt.category, activity_names:dt.activity_names, activity_locations:dt.activity_locations, anchor_id:dt.anchor_activity.present? ? dt.anchor_activity.id.to_s : ''}}

          if dates.nil?
            {:failure => "cannot find this dates"}
          else
            MyDate.set_browsed_count(user, all_dates)
            GoogleAnalytics.new.event('date', 'get my dates by time', user.name, user.id)
            {success: my_dates}
          end
        else
          {:failure => "not exist this ueser "}
        end
      end

      # Get All Activities from date near 10 mile
      # GET: /api/v1/activities/activities_near_by_date
      # PARAMS:
      #    token:     String *required
      #    date_id:   String *required
      #    page:      Integer( page number )
      # RESULTS:
      #    all activities
      get :activities_near_by_date do
        user = User.find_by_token params[:token]
        if user.present?
          date = MyDate.where(id:params[:date_id]).first
          if date.present?
            return {failure: "cannot find activities for this date"} if date.activities.blank?
            m_ids = []
            date.activities.each do |act|
              geo_loc   = act.merchant.geo_location
              geo_locs  = GeoLocation.near(geo_loc,10)              
              ids = geo_locs.map{|geo| geo.merchant.id.to_s}
              m_ids = m_ids | Merchant.in(id:ids).where(active:true).map{|m| m.id.to_s}
            end
            m_ids = m_ids - date.activities.map{|a| a.merchant.id.to_s} 
            acts = Activity.in(merchant_id:m_ids.uniq).paginate(page: params[:page], :per_page => Activity::ACTIVITY_PAGE_LIMIT)
            my_act_ids  = user.activities.present? ? user.activities.map{|act| act.id} : []
            activities = acts.map{|act|{id:act.id.to_s,name:act.name,category:act.categories_str,venue:act.merchant_name,city:act.full_city,pricing:act.get_price,img_url:act.first_img,like:my_act_ids.include?(act.id)}}
            Activity.set_browsed_count(user, acts)
            {success: activities}
          else
            {failure: "cannot find date"}
          end
        else
          {:failure => "cannot find user"}
        end
      end

    end    
  end
end