class CreateChathistories < ActiveRecord::Migration
  def change
    create_table :chathistories do |t|
      t.integer :receiver_id
      t.integer :sender_id
      t.text :chat_content
      t.datetime :chat_date

      t.timestamps
    end
  end
end
