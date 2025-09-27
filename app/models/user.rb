class User < ApplicationRecord
  self.abstract_class = true
  self.table_name = "auth.users"

  has_many :feeds, foreign_key: :user_id, primary_key: :id

  def self.connection
    return super if Rails.env.test?
    establish_connection :supabase
    super
  end
end
