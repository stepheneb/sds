class CreateOfferingAttributes < ActiveRecord::Migration
  def self.up
    begin
	    create_table 'sds_offerings_attributes' do |t|
	      t.column :offering_id, :int, :size => 11
	      t.column :name, :text, :null => false
	      t.column :value, :text
	    end
    rescue Exception => e
      if e.to_s.include?("Table 'sds_offerings_attributes' already exists")
        # don't worry about it, the db probably came from an sds 1.0 version in which this migration is #43
      else
        raise e
      end
    end
  end

  def self.down
    drop_table 'sds_offerings_attributes'
  end
end