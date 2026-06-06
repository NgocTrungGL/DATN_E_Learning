class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  def self.random_order_sql
    adapter = connection_db_config.adapter.downcase
    adapter.include?("postgres") ? Arel.sql("RANDOM()") : Arel.sql("RAND()")
  end
end
