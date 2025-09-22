class CreateFeeds < ActiveRecord::Migration[8.0]
  def change
    create_table :feeds do |t|
      t.string :user_id
      t.string :url
      t.text :selectors

      t.timestamps
    end
  end
end
