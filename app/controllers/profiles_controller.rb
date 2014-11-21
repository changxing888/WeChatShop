class ProfilesController < ApplicationController
  before_filter :authenticate_user!
  rescue_from ActionView::MissingTemplate, :with => :render_html

  def render_html
    if not request.format == "html" and Rails.env.production?
      #render :format => "html"
      render formats: [:html]
    else
      raise ActionView::MissingTemplate
    end
  end

  def index
  end

  def commitment
  end

  def education
    @education = Education.new
    #@education = current_user.educations.build
  end

  def experience
    @experience = Experience.new
    ap @experience
    ap "aaaaaaa"
  end

  def verification
  end

  def about
  end


  def send_phone_code
    @user = User.where(:uid => params[:token]).first
    raise ActionController::RoutingError.new('Not Found') unless @user

    # set up a client to talk to the Twilio REST API
    client = Twilio::REST::Client.new(ENV["TWILIO_ID"], ENV["TWILIO_TOKEN"])
    client.account.sms.messages.create({:from => ENV["TWILIO_NUMBER"], :to => params[:phone], :body => "Your verification code is: \'#{@user.phone_verification_code}\'"})
    @user.update_attribute(:phone, params[:phone])
    render :nothing => true
  end

  def verify_phone_code
    @user = User.where(:uid => params[:token]).first
    raise ActionController::RoutingError.new('Not Found') unless @user

    if params[:code] && params[:code].downcase  == @user.phone_verification_code.downcase
      @user.update_attribute(:phone_verified, true)
      @user.process_referrals
    else
      raise "Verification code does not match"
    end
    render :nothing => true
  end

  def unlink
    case params[:type]
    when "phone"
      current_user.phone = ""
      current_user.phone_verified = false
      current_user.phone_verification_code = Request.generate_activation_code
      current_user.save
    when "facebook"
      current_user.update_attributes({:fb_authorized => 0, :fb_uid => nil})
    when "twitter"
      current_user.update_attributes({:twitter_authorized => 0, :twitter_uid => nil})
    when "google"
      current_user.update_attributes({:gplus_authorized => 0, :gplus_uid => nil})
    when "linkedin"
      current_user.update_attributes({:linkedin_authorized => 0, :linkedin_uid => nil})
    end
    redirect_to verification_profiles_path, :notice => notice
  end


  def update
    respond_to do |wants|
      if current_user.update_attributes(params[:user])
        flash[:notice] = "Your profile was updated successfully. <a target='_blank' href=#{public_profile_path(current_user.permalink)}>View profile.</a>"
        wants.html { redirect_to(profiles_path) }
        wants.xml  { head :ok }
      else
        flash[:error] = "Please review the problems below"
        wants.html { render :action => "index" }
        wants.xml  { render :xml => @model.errors, :status => :unprocessable_entity }
      end
    end
  end
end

