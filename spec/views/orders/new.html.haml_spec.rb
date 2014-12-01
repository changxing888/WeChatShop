require 'rails_helper'

RSpec.describe "orders/new", :type => :view do
  before(:each) do
    assign(:order, Order.new(
      :name => "MyString",
      :number => 1,
      :count => 1,
      :user => nil,
      :status => 1,
      :position => "MyString"
    ))
  end

  it "renders new order form" do
    render

    assert_select "form[action=?][method=?]", orders_path, "post" do

      assert_select "input#order_name[name=?]", "order[name]"

      assert_select "input#order_number[name=?]", "order[number]"

      assert_select "input#order_count[name=?]", "order[count]"

      assert_select "input#order_user_id[name=?]", "order[user_id]"

      assert_select "input#order_status[name=?]", "order[status]"

      assert_select "input#order_position[name=?]", "order[position]"
    end
  end
end
