require 'rails_helper'

RSpec.describe "products/new", :type => :view do
  before(:each) do
    assign(:product, Product.new(
      :name => "MyString",
      :number => 1,
      :count => 1,
      :user => nil,
      :status => 1,
      :position => "MyString"
    ))
  end

  it "renders new product form" do
    render

    assert_select "form[action=?][method=?]", products_path, "post" do

      assert_select "input#product_name[name=?]", "product[name]"

      assert_select "input#product_number[name=?]", "product[number]"

      assert_select "input#product_count[name=?]", "product[count]"

      assert_select "input#product_user_id[name=?]", "product[user_id]"

      assert_select "input#product_status[name=?]", "product[status]"

      assert_select "input#product_position[name=?]", "product[position]"
    end
  end
end
