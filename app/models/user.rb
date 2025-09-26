class User < ApplicationRecord
  self.abstract_class = true
  self.table_name = "auth.users"
  establish_connection :supabase
  
  has_many :feeds, foreign_key: :user_id, primary_key: :id
end