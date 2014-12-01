class CreateProducts < ActiveRecord::Migration
  def change
    create_table :products do |t|
      t.string :name
      t.integer :number
      t.integer :count
      t.belongs_to :user, index: true
      t.integer :status
      t.string :position
      t.datetime :date

      t.timestamps
    end
  end
end
