class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table "users"  do |t|
      t.column :login, :string
      t.column :email, :string
      t.column :first_name, :string
      t.column :last_name, :string
      t.column :password_hash, :string
      t.column :crypted_password, :string, :limit => 40
      t.column :salt, :string, :limit => 40
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
      t.column :remember_token, :string
      t.column :remember_token_expires_at, :datetime
    end
    
    create_table "roles", :force => true do |t|
      t.column :title, :string
    end
    
    create_table "roles_users", :id => false, :force => true do |t|
      t.column :role_id, :integer
      t.column "user_id", :integer
    end
    
    # Role.create(:title => 'sds_admin')
    # Role.create(:title => 'portal_admin')
    # Role.create(:title => 'portal_user')
    # 
# This doesn't work because the User table doesn't exist at this point in the migration
#    u = User.new(:login => "stephen", :email => "stephen@concord.org", :password_hash => "fd035914661eb4f8b00a57be66a2be2b", :first_name => "Stephen", :last_name => "Bannasch")
#    u.save(false)
#    u.roles << Role.find_by_title('sds_admin')
#    u.save(false)
       
  end

  def self.down
    drop_table "users"
    drop_table "roles_users"
    drop_table "roles"
  end
end

