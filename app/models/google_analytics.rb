class GoogleAnalytics

  GOOGLE_ANALYTICS_SETTINGS = HashWithIndifferentAccess.new
  GOOGLE_ANALYTICS_SETTINGS[:endpoint]       = 'http://www.google-analytics.com/collect'
  GOOGLE_ANALYTICS_SETTINGS[:version]        = 1
  GOOGLE_ANALYTICS_SETTINGS[:tracking_code] = 'UA-46415405-2'                                               
  GOOGLE_ANALYTICS_SETTINGS[:hostname]       = 'datezr.herokuapp.com'
  def event(category, action, label, client_id = '555')
    params = {
      v:GOOGLE_ANALYTICS_SETTINGS[:version],
      tid:GOOGLE_ANALYTICS_SETTINGS[:tracking_code],
      cid:client_id,
      t:"event",
      ec:category,
      ea:action,
      el:label
    }

    begin
      RestClient.get(GOOGLE_ANALYTICS_SETTINGS[:endpoint], params:params, timeout: 4, open_timeout: 4)
      return true
    rescue RestClient::Exception => rex
      return false      
    end
  end
  #handle_asynchronously :event, :priority =>20

  def page(page, title, client_id)
    params = {
      v:GOOGLE_ANALYTICS_SETTINGS[:version],
      tid:GOOGLE_ANALYTICS_SETTINGS[:tracking_code],
      cid:client_id,
      t:"pageview",
      dh:GOOGLE_ANALYTICS_SETTINGS[:hostname] ,
      dp:page,
      dt:title
    }

    begin
      RestClient.get(GOOGLE_ANALYTICS_SETTINGS[:endpoint], params:params, timeout: 4, open_timeout: 4)
      return true
    rescue RestClient::Exception => rex
      return false      
    end
  end
  #handle_asynchronously :page, :priority =>20
end