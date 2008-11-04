# == Schema Information
# Schema version: 58
#
# Table name: sds_users
#
#  id                        :integer(11)   not null, primary key
#  login                     :string(255)   
#  email                     :string(255)   
#  first_name                :string(255)   
#  last_name                 :string(255)   
#  password_hash             :string(255)   
#  crypted_password          :string(40)    
#  salt                      :string(40)    
#  created_at                :datetime      
#  updated_at                :datetime      
#  remember_token            :string(255)   
#  remember_token_expires_at :datetime      
#

require 'digest/sha1'
require 'digest/md5' 

class User < ActiveRecord::Base
  include Authentication
  include Authentication::ByPassword
  include Authentication::ByCookieToken
  
#  acts_as_authorized_user

  has_and_belongs_to_many :roles, options = {:join_table => "roles_users"}

  # Virtual attribute for the unencrypted password
  attr_accessor :password

  validates_presence_of     :login, :email

  validates_each :first_name, :last_name, :login, :email do |model, attr, value| 
    unless value =~ /\S+/ 
      model.errors.add(attr, "must not be empty") 
    end 
  end
  
  validates_length_of       :login,    :within => 3..40
  validates_length_of       :email,    :within => 3..100
  validates_uniqueness_of   :login, :email, :case_sensitive => false

  before_save :encrypt_password
  before_create :make_activation_code
  
  after_create :add_member_role
  
  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  # attr_accessible :login, :email, :first_name, :last_name, :password, :password_confirmation

  def self.search(search, page)
    paginate :per_page => 20, :page => page,
             :conditions => ['first_name like ? OR last_name like ? OR login like ? OR email like ?',"%#{search}%","%#{search}%", "%#{search}%", "%#{search}%"], :order => 'created_at ASC'
  end

  def name
    "#{first_name} #{last_name}"
  end
  
  # Returns True if User has one of the roles.
  # False otherwize.
  #
  # You can pass in a sequence of strings:
  #
  #  user.has_role("admin", "manager")
  #
  # or an array of strings:
  #
  #  user.has_role(%w{admin manager})
  #
  def has_role(*role_list)
    (roles.map{ |r| r.title.downcase } & role_list.flatten).length > 0
  end

  def does_not_have_role(*role_list)
    !has_role(role_list)
  end
  
  def add_member_role
    if self.roles.size == 0
      self.roles << Role.find_by_title('member')
    end
  end
  
  # Activates the user in the database.
  def activate
    @activated = true
    self.activated_at = Time.now.utc
    self.activation_code = nil
    save(false)
  end

  def active?
    # the existence of an activation code means they have not activated yet
    activation_code.nil?
  end

  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  def self.authenticate(login, password)
    return nil if login.blank? || password.blank?
    u = find :first, :conditions => ['login = ? OR email = ? and activated_at IS NOT NULL', login, login] # need to get the salt
    u && u.authenticated?(password) ? u : nil
  end

  # Returns true if the user has just been activated.
  def recently_activated?
    @activated
  end

  protected
    
    def make_activation_code

      self.activation_code = Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join )
    end
    
end
