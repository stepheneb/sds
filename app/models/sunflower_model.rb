class SunflowerModel < ActiveRecord::Base

  def self.connection_possible?
    begin
      find(:first)
      true
    rescue SystemCallError
      false
    end
  end
  
#  self.table_name_prefix = ""
  establish_connection :sunflower

end
