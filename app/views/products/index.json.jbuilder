json.array!(@products) do |product|
  json.extract! product, :id, :name, :number, :count, :user_id, :status, :position, :date
  json.url product_url(product, format: :json)
end
