class Chart
  DURATION_OPTIONS = %w[today 1 year all_time]
  def self.user_stats_chart(duration, location)
    cats = {}
    cats['today'] = [*0..23]
    days = Time.days_in_month(Time.now.month)
    cats['1']      = [*1..days]
    cats['year']  = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun','Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
    
    chart_data={'total_users'=>[],'new_users'=>[],'concur_users'=>[], 'freaqu_users'=>[]}
    case duration
    when DURATION_OPTIONS[0]
      date = DateTime.now.midnight
      [*0..23].each do |time|
        if location.present?
          chart_data['total_users']  << total_users  = User.where(:created_at.lt => date+1.hour, :location_id => location).count
          chart_data['new_users']    << new_users    = User.where(:created_at.gte => date, :created_at.lt =>date+1.hour, :location_id => location).count
          chart_data['concur_users'] << concur_users = UserTimeLog.where(:st_time.gte => date, :st_time.lt =>date+1.hour, :location_id => location).map(&:user_id).uniq.count
          if total_users > concur_users
            freaqu_users = total_users - concur_users
          else
            freaqu_users = 0
          end
          chart_data['freaqu_users'] << freaqu_users
        else
          chart_data['total_users']  << total_users  = User.where(:created_at.lt => date).count
          chart_data['new_users']    << new_users    = User.where(:created_at.gte => date, :created_at.lt =>date+1.hour).count
          chart_data['concur_users'] << concur_users = UserTimeLog.where(:st_time.gte => date, :st_time.lt =>date+1.hour).map(&:user_id).uniq.count
          if total_users > concur_users
            freaqu_users = total_users - concur_users
          else
            freaqu_users = 0
          end
          chart_data['freaqu_users'] << freaqu_users
        end
        date = date + 1.hour
      end
    when DURATION_OPTIONS[1]
      days   = Time.days_in_month(Time.now.month)
      date = (DateTime.now-(DateTime.now.day-1)).midnight
      [*1..days].each do |d|
        if location.present?        
          chart_data['total_users']  << total_users  = User.where(:created_at.lt => date+1.day, :location_id => location).count
          chart_data['new_users']    << new_users    = User.where(:created_at.gte => date, :created_at.lt =>date+1.day, :location_id => location).count
          chart_data['concur_users'] << concur_users = UserTimeLog.where(:st_time.gte => date, :st_time.lt =>date+1.day, :location_id => location).map(&:user_id).uniq.count
          if total_users > concur_users
            freaqu_users = total_users - concur_users
          else
            freaqu_users = 0
          end
          chart_data['freaqu_users'] << freaqu_users
        else
          chart_data['total_users']  << total_users  = User.where(:created_at.lt => date+1.day).count
          chart_data['new_users']    << new_users    = User.where(:created_at.gte => date, :created_at.lt =>date+1.day).count
          chart_data['concur_users'] << concur_users = UserTimeLog.where(:st_time.gte => date, :st_time.lt =>date+1.day).map(&:user_id).uniq.count
          if total_users > concur_users
            freaqu_users = total_users - concur_users
          else
            freaqu_users = 0
          end
          chart_data['freaqu_users'] << freaqu_users
        end
        date = date + 1.day
      end
    when DURATION_OPTIONS[2]
      date  = DateTime.new(Date.today.year,1,1)
      [*1..12].each do |m|
        if location.present?
          chart_data['total_users']  << total_users  = User.where(:created_at.lt => date+1.month, :location_id => location).count
          chart_data['new_users']    << new_users    = User.where(:created_at.gte => date, :created_at.lt =>date+1.month, :location_id => location).count
          chart_data['concur_users'] << concur_users = UserTimeLog.where(:st_time.gte => date, :st_time.lt =>date+1.month, :location_id => location).map(&:user_id).uniq.count
          if total_users > concur_users
            freaqu_users = total_users - concur_users
          else
            freaqu_users = 0
          end
          chart_data['freaqu_users'] << freaqu_users
        else
          chart_data['total_users']  << total_users  = User.where(:created_at.lt => date+1.month).count
          chart_data['new_users']    << new_users    = User.where(:created_at.gte => date, :created_at.lt =>date+1.month).count
          chart_data['concur_users'] << concur_users = UserTimeLog.where(:st_time.gte => date, :st_time.lt =>date+1.month).map(&:user_id).uniq.count
          if total_users > concur_users
            freaqu_users = total_users - concur_users
          else
            freaqu_users = 0
          end
          chart_data['freaqu_users'] << freaqu_users
        end
        date = date + 1.month
      end
    when DURATION_OPTIONS[3]
      
    end
    
    @chart = LazyHighCharts::HighChart.new('basic_line') do |f|
      f.chart({ type: 'line',
                marginRight: 25,
                marginBottom: 30 })
      f.title({  text: 'User Statistical data',
                 x: -20
      })
      f.xAxis({
        categories: cats[duration]
      })
      f.yAxis({
        title: {
          text: 'User Stats (Man)'
        },
        plotLines: [{
          value: 0,
          width: 1,
          color: '#808080'
        }]
      })
      f.tooltip({
        valueSuffix: ' People'
      })
      f.legend({
        layout: 'horizontal',
        align: 'top',
        verticalAlign: 'top',
        x: 20,
        y: 40,
        borderWidth: 0
      })
      f.subtitle({
        text: 'Source: App.Datezr.com',
        x: -20
      })
      f.series({
        name: 'Total',
        data: chart_data['total_users']
      })
      f.series(
        name: 'New Account',
        data: chart_data['new_users']
      )
      f.series({
        name: 'Concurrent',
        data: chart_data['concur_users']
      })
      f.series({
          name: 'Freaquent',
          data: chart_data['freaqu_users']
      })
    end
  end

  def self.content_stats_chart(duration, location)
    cats = {}
    cats['today'] = [*0..23]
    days = Time.days_in_month(Time.now.month)
    cats['1']     = [*1..days]
    cats['year']  = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun','Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
    
    chart_data={'viwed_acts'=>[],'viewed_dates'=>[],'created_dates'=>[], 'saved_acts'=>[], 'saved_dates'=>[]}
    case duration
    when DURATION_OPTIONS[0]
      date = DateTime.now.midnight
      [*0..23].each do |time|
        if location.present?
          chart_data['viwed_acts']    << UserActivityDateStatistic.viewed_activities.where(:created_at.gt => date, :created_at.lte => date+1.hour).count
          chart_data['viewed_dates']  << UserActivityDateStatistic.viewed_dates.where(:created_at.gt => date, :created_at.lte => date+1.hour).count
          chart_data['created_dates'] << UserActivityDateStatistic.created_dates.where(:created_at.gt => date, :created_at.lte => date+1.hour).count
          chart_data['saved_acts']    << UserActivityDateStatistic.saved_activities.where(:created_at.gt => date, :created_at.lte => date+1.hour).count
          chart_data['saved_dates']   << UserActivityDateStatistic.saved_dates.where(:created_at.gt => date, :created_at.lte => date+1.hour).count
        else
          chart_data['viwed_acts']    << UserActivityDateStatistic.viewed_activities.where(:created_at.gt => date, :created_at.lte => date+1.hour).count
          chart_data['viewed_dates']  << UserActivityDateStatistic.viewed_dates.where(:created_at.gt => date, :created_at.lte => date+1.hour).count
          chart_data['created_dates'] << UserActivityDateStatistic.created_dates.where(:created_at.gt => date, :created_at.lte => date+1.hour).count
          chart_data['saved_acts']    << UserActivityDateStatistic.saved_activities.where(:created_at.gt => date, :created_at.lte => date+1.hour).count
          chart_data['saved_dates']   << UserActivityDateStatistic.saved_dates.where(:created_at.gt => date, :created_at.lte => date+1.hour).count
        end
        date = date + 1.hour
      end
    when DURATION_OPTIONS[1]
      days   = Time.days_in_month(Time.now.month)
      date = (DateTime.now-(DateTime.now.day-1)).midnight
      [*1..days].each do |d|
        if location.present?
          chart_data['viwed_acts']    << UserActivityDateStatistic.viewed_activities.where(:created_at.gt => date, :created_at.lte => date+1.day).count
          chart_data['viewed_dates']  << UserActivityDateStatistic.viewed_dates.where(:created_at.gt => date, :created_at.lte => date+1.day).count
          chart_data['created_dates'] << UserActivityDateStatistic.created_dates.where(:created_at.gt => date, :created_at.lte => date+1.day).count
          chart_data['saved_acts']    << UserActivityDateStatistic.saved_activities.where(:created_at.gt => date, :created_at.lte => date+1.day).count
          chart_data['saved_dates']   << UserActivityDateStatistic.saved_dates.where(:created_at.gt => date, :created_at.lte => date+1.day).count
        else
          chart_data['viwed_acts']    << UserActivityDateStatistic.viewed_activities.where(:created_at.gt => date, :created_at.lte => date+1.day).count
          chart_data['viewed_dates']  << UserActivityDateStatistic.viewed_dates.where(:created_at.gt => date, :created_at.lte => date+1.day).count
          chart_data['created_dates'] << UserActivityDateStatistic.created_dates.where(:created_at.gt => date, :created_at.lte => date+1.day).count
          chart_data['saved_acts']    << UserActivityDateStatistic.saved_activities.where(:created_at.gt => date, :created_at.lte => date+1.day).count
          chart_data['saved_dates']   << UserActivityDateStatistic.saved_dates.where(:created_at.gt => date, :created_at.lte => date+1.day).count
        end
        date = date + 1.day
      end
    when DURATION_OPTIONS[2]
      date  = DateTime.new(Date.today.year,1,1)
      [*1..12].each do |m|
        if location.present?
          chart_data['viwed_acts']    << UserActivityDateStatistic.viewed_activities.where(:created_at.gt => date, :created_at.lte => date+1.month).count
          chart_data['viewed_dates']  << UserActivityDateStatistic.viewed_dates.where(:created_at.gt => date, :created_at.lte => date+1.month).count
          chart_data['created_dates'] << UserActivityDateStatistic.created_dates.where(:created_at.gt => date, :created_at.lte => date+1.month).count
          chart_data['saved_acts']    << UserActivityDateStatistic.saved_activities.where(:created_at.gt => date, :created_at.lte => date+1.month).count
          chart_data['saved_dates']   << UserActivityDateStatistic.saved_dates.where(:created_at.gt => date, :created_at.lte => date+1.month).count
        else
          chart_data['viwed_acts']    << UserActivityDateStatistic.viewed_activities.where(:created_at.gt => date, :created_at.lte => date+1.month).count
          chart_data['viewed_dates']  << UserActivityDateStatistic.viewed_dates.where(:created_at.gt => date, :created_at.lte => date+1.month).count
          chart_data['created_dates'] << UserActivityDateStatistic.created_dates.where(:created_at.gt => date, :created_at.lte => date+1.month).count
          chart_data['saved_acts']    << UserActivityDateStatistic.saved_activities.where(:created_at.gt => date, :created_at.lte => date+1.month).count
          chart_data['saved_dates']   << UserActivityDateStatistic.saved_dates.where(:created_at.gt => date, :created_at.lte => date+1.month).count
        end
        date = date + 1.month      
      end
    when DURATION_OPTIONS[3]
      
    end
    
    @chart = LazyHighCharts::HighChart.new('basic_line') do |f|
      f.chart({ type: 'line',
                marginRight: 25,
                marginBottom: 30 })
      f.title({  text: 'Content Engagement Stats',
                 x: -20
      })
      f.xAxis({
        categories: cats[duration]
      })
      f.yAxis({
        title: {
          text: 'User Stats (Man)'
        },
        plotLines: [{
          value: 0,
          width: 1,
          color: '#808080'
        }]
      })
      f.tooltip({
        valueSuffix: ''
      })
      f.legend({
        layout: 'horizontal',
        align: 'top',
        verticalAlign: 'top',
        x: 20,
        y: 40,
        borderWidth: 0
      })
      f.subtitle({
        text: 'Source: App.Datezr.com',
        x: -20
      })
      f.series({
        name: 'Viewed Activities',
        data: chart_data['viwed_acts']
      })
      f.series(
        name: 'Viewed Dates',
        data: chart_data['viewed_dates']
      )
      f.series({
        name: 'Created Dates',
        data: chart_data['created_dates']
      })
      f.series({
          name: 'Saved Activities',
          data: chart_data['saved_acts']
      })
      f.series({
          name: 'Saved Dates',
          data: chart_data['saved_dates']
      })
    end
  end

  def self.trending_stats_chart(duration, location)
    all_dates = {}
    all_acts = {}
    @acts_chart_data = {}
    @dates_chart_data = {}    
    brd_weight,vwd_weight,svd_weight,shd_weight,add_weight,chd_weight = [*1..6]
    count = [0]*6
    dt_count = [0]*6
    date_types = DateType.all.order_by('order_id ASC')
    case duration
    when DURATION_OPTIONS[0]
      date = DateTime.now.midnight      
      date_types.each do |dt|
        dates = MyDate.search_dates(dt, 2, date, location)
        dt_count[0] = dt_count[0] + brd_count = dates.browsed_count*brd_weight
        dt_count[1] = dt_count[1] + vwd_count = dates.viewed_count*vwd_weight
        dt_count[2] = dt_count[2] + svd_count = dates.saved_count*svd_weight
        dt_count[3] = dt_count[3] + shd_count = dates.shared_count*shd_weight
        all_dates[dt.name.to_sym] = {:br=>brd_count, :vi=>vwd_count, :sa=>svd_count, :sh=>shd_count}

        acts = MyDate.activities(dates)
        count[0] = count[0] + brd_count = acts.browsed_count*brd_weight
        count[1] = count[1] + vwd_count = acts.viewed_count*vwd_weight
        count[2] = count[2] + svd_count = acts.saved_count*svd_weight
        count[3] = count[3] + shd_count = acts.shared_count*shd_weight
        count[4] = count[4] + add_count = acts.added_count*add_weight
        count[5] = count[5] + chd_count = acts.checked_count*chd_weight
        all_acts[dt.name.to_sym] = {:br=>brd_count, :vi=>vwd_count, :sa=>svd_count, :sh=>shd_count, :ad=>add_count, :ch=>chd_count}
      end
    when DURATION_OPTIONS[1]
      date = (DateTime.now-(DateTime.now.day-1)).midnight
      date_types.each do |dt|
        dates = MyDate.search_dates(dt, 2, date, location)
        dt_count[0] = dt_count[0] + brd_count = dates.browsed_count*brd_weight
        dt_count[1] = dt_count[1] + vwd_count = dates.viewed_count*vwd_weight
        dt_count[2] = dt_count[2] + svd_count = dates.saved_count*svd_weight
        dt_count[3] = dt_count[3] + shd_count = dates.shared_count*shd_weight
        all_dates[dt.name.to_sym] = {:br=>brd_count, :vi=>vwd_count, :sa=>svd_count, :sh=>shd_count}

        acts = MyDate.activities(dates)
        count[0] = count[0] + brd_count = acts.browsed_count*brd_weight
        count[1] = count[1] + vwd_count = acts.viewed_count*vwd_weight
        count[2] = count[2] + svd_count = acts.saved_count*svd_weight
        count[3] = count[3] + shd_count = acts.shared_count*shd_weight
        count[4] = count[4] + add_count = acts.added_count*add_weight
        count[5] = count[5] + chd_count = acts.checked_count*chd_weight
        all_acts[dt.name.to_sym] = {:br=>brd_count, :vi=>vwd_count, :sa=>svd_count, :sh=>shd_count, :ad=>add_count, :ch=>chd_count}
      end
    when DURATION_OPTIONS[2]
      date  = DateTime.new(Date.today.year,1,1)
      date_types.each do |dt|
        dates = MyDate.search_dates(dt, 2, date, location)
        dt_count[0] = dt_count[0] + brd_count = dates.browsed_count*brd_weight
        dt_count[1] = dt_count[1] + vwd_count = dates.viewed_count*vwd_weight
        dt_count[2] = dt_count[2] + svd_count = dates.saved_count*svd_weight
        dt_count[3] = dt_count[3] + shd_count = dates.shared_count*shd_weight
        all_dates[dt.name.to_sym] = {:br=>brd_count, :vi=>vwd_count, :sa=>svd_count, :sh=>shd_count}

        acts = MyDate.activities(dates)
        count[0] = count[0] + brd_count = acts.browsed_count*brd_weight
        count[1] = count[1] + vwd_count = acts.viewed_count*vwd_weight
        count[2] = count[2] + svd_count = acts.saved_count*svd_weight
        count[3] = count[3] + shd_count = acts.shared_count*shd_weight
        count[4] = count[4] + add_count = acts.added_count*add_weight
        count[5] = count[5] + chd_count = acts.checked_count*chd_weight
        all_acts[dt.name.to_sym] = {:br=>brd_count, :vi=>vwd_count, :sa=>svd_count, :sh=>shd_count, :ad=>add_count, :ch=>chd_count}
      end
    when DURATION_OPTIONS[3]
      
    end
    # calculating dates chart data
    count_all = dt_count.sum
    all_dates.each do |dt|      
      br = dt[1][:br] == 0 ? 0 : (dt[1][:br]/count_all.to_f*100)
      vi = dt[1][:vi] == 0 ? 0 : (dt[1][:vi]/count_all.to_f*100)
      sa = dt[1][:sa] == 0 ? 0 : (dt[1][:sa]/count_all.to_f*100)
      sh = dt[1][:sh] == 0 ? 0 : (dt[1][:sh]/count_all.to_f*100)
      @dates_chart_data[dt[0].to_s] = (br+vi+sa+sh).round(1)
    end

    #calculating activity chart data
    count_all = count.sum
    all_acts.each do |act|      
      br = act[1][:br] == 0 ? 0 : (act[1][:br]/count_all.to_f*100)
      vi = act[1][:vi] == 0 ? 0 : (act[1][:vi]/count_all.to_f*100)
      sa = act[1][:sa] == 0 ? 0 : (act[1][:sa]/count_all.to_f*100)
      sh = act[1][:sh] == 0 ? 0 : (act[1][:sh]/count_all.to_f*100)
      ad = act[1][:ad] == 0 ? 0 : (act[1][:ad]/count_all.to_f*100)
      ch = act[1][:ch] == 0 ? 0 : (act[1][:ch]/count_all.to_f*100)
      @acts_chart_data[act[0].to_s] = (br+vi+sa+sh+ad+ch).round(1)
    end

    activity_chart = LazyHighCharts::HighChart.new('pie') do |f|
      f.chart({:defaultSeriesType=>"pie" , :margin=> [30, 20, 30, 20]} )
      series = {
               :type=> 'pie',
               :name=> 'Activity of Date Type',
               :data=> @acts_chart_data.to_a
      }
      f.series(series)
      f.options[:title][:text] = "Trending Activities "
      #f.legend(:layout=> 'vertical',:style=> {:left=> 'auto', :bottom=> 'auto',:right=> '50px',:top=> '100px'}) 
      f.plot_options(:pie=>{
        :allowPointSelect=>true, 
        :cursor=>"pointer" , 
        :dataLabels=>{
          :enabled=>true,
          :color=>"black",
          :style=>{
            :font=>"13px Trebuchet MS, Verdana, sans-serif"
          }
        }
      })
    end

    date_chart = LazyHighCharts::HighChart.new('pie') do |f|
      f.chart({:defaultSeriesType=>"pie" , :margin=> [30, 20, 30, 20]} )
      series = {
               :type=> 'pie',
               :name=> 'Dates of Date Type',
               :data=> @dates_chart_data.to_a
      }
      f.series(series)
      f.options[:title][:text] = "Trending Dates"
      f.legend(:layout=> 'vertical',:style=> {:left=> '10', :bottom=> '10',:right=> '150px',:top=> '200px'}) 
      f.plot_options(:pie=>{
        :allowPointSelect=>true, 
        :cursor=>"pointer" , 
        :dataLabels=>{
          :enabled=>true,
          :color=>"black",
          :style=>{
            :font=>"13px Trebuchet MS, Verdana, sans-serif"
          }
        }
      })
    end
    [activity_chart, date_chart]
  end
end

