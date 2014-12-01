require 'rails_helper'

RSpec.describe "products/index", :type => :view do
  before(:each) do
    assign(:products, [
      Product.create!(
        :name => "Name",
        :number => 1,
        :count => 2,
        :user => nil,
        :status => 3,
        :position => "Position"
      ),
      Product.create!(
        :name => "Name",
        :number => 1,
        :count => 2,
        :user => nil,
        :status => 3,
        :position => "Position"
      )
    ])
  end

  it "renders a list of products" do
    render
    assert_select "tr>td", :text => "Name".to_s, :count => 2
    assert_select "tr>td", :text => 1.to_s, :count => 2
    assert_select "tr>td", :text => 2.to_s, :count => 2
    assert_select "tr>td", :text => nil.to_s, :count => 2
    assert_select "tr>td", :text => 3.to_s, :count => 2
    assert_select "tr>td", :text => "Position".to_s, :count => 2
  end
end
