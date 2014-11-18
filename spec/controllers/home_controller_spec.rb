require 'rails_helper'

RSpec.describe HomeController, :type => :controller do

  describe "GET index" do
    it "returns http success" do
      get :index
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET about_us" do
    it "returns http success" do
      get :about_us
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET contact_us" do
    it "returns http success" do
      get :contact_us
      expect(response).to have_http_status(:success)
    end
  end

end
