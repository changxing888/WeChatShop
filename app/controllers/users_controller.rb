  class UsersController < ApplicationController
  # helper_method :current_user?, :admin_user?
  include UsersHelper

  before_action :user_signed_in?, only:[:index, :show, :edit, :update, :destroy]
  before_action :correct_user,    only:[:edit, :update]
  before_action :admin_user,      only:[:index, :destroy]

  def index
    @users = User.all    
    start_date = Date.today - 13.months
    end_date = Date.today
    number_of_months = (end_date.year*12+end_date.month)-(start_date.year*12+start_date.month)
    @months = (number_of_months+1).times.each_with_object([]) do |count, array|
      date = start_date.beginning_of_month + count.months
      opt = Date::MONTHNAMES[date.month][0..2] + "-" + date.year.to_s
      val = start_date.beginning_of_month + count.months
      array << [opt, val]
    end
    @selected_month = @months.last
  end

  def show
  end

  def edit
  end

  def udpate
  end

  def destroy
    User.find(params[:id]).destroy
    flash[:success] = "User deleted"
    redirect_to users_url
  end
end
