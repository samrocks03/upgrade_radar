# frozen_string_literal: true

class DatabaseCheck
  def self.run
    conn = ActiveRecord::Base.connection_pool.connection
    conn.execute("SELECT 1")
  end
end
