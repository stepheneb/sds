class SdsUser < ActiveRecord::Base
  set_table_name "sds_sds_users"

  has_and_belongs_to_many :roles, options = {:join_table => "sds_roles_sds_users"}

  require 'digest/sha1'
  require 'digest/md5' 

  # Virtual attribute for the unencrypted password
  attr_accessor :password

  validates_presence_of     :login, :email
  validates_presence_of     :password,                   :if => :password_required?
  validates_presence_of     :password_confirmation,      :if => :password_required?
  validates_length_of       :password, :within => 3..40, :if => :password_required?
  validates_confirmation_of :password,                   :if => :password_required?
  validates_length_of       :login,    :within => 3..40
  validates_length_of       :email,    :within => 3..100
  validates_uniqueness_of   :login, :email, :case_sensitive => false
  before_save :encrypt_password

  def name
    "#{first_name} #{last_name}"
  end

  # Authenticates an sds_user by their login name and unencrypted password.  Returns the sds_user or nil.
  def self.authenticate(identifier, password)
    unless remote_authenticate(identifier, password)
      local_authenticate(identifier, password)
    end
  end

  def self.synch_with_local_sds_user(cc_user, password)
    sds_user = SdsUser.find_by_email(ccuser.user_email) unless sds_user = SdsUser.find_by_login(ccuser.user_username)
    if sds_user.blank?
      sds_user = SdsUser.new
      sds_user.login = ccuser.user_username
      sds_user.email = ccuser.user_email
      sds_user.first_name = ccuser.user_first_name 
      sds_user.last_name = ccuser.user_last_name
      sds_user.save
    else
      if sds_user.password_hash != ccuser.user_password
        sds_user.save
      end
    end
  end
    
# ----

  def self.remote_authenticate(identifier, password)
    begin
      if ccuser = SunflowerMystriUser.find_user(identifier)
        if remote_authenticated?(password, ccuser.user_password)
          synch_with_local_sds_user(cc_user, password)
        else
          nil
        end
      else
        nil
      end
    rescue Mysql::Error
      nil
    end
  end
  
  def self.remote_authenticated?(password, remote_password)
    (remote_encrypt(password) == remote_encrypt(remote_password))
  end

  def self.local_authenticate(identifier, password)
    u = SdsUser.find_by_login(identifier) || SdsUser.find_by_email(identifier)
    u && u.local_authenticated?(password) ? u : nil
  end

  def local_authenticated?(password)
    if crypted_password
      crypted_password == salted_sha_encrypt(password)
    else
      if password_hash == md5_encrypt(password)
        crypted_password = salted_sha_encrypt(password)
        true
      end
    end
  end
  
  # Encrypts some data with the salt.
  def self.local_encrypt(password, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end

  # Encrypts the password with the sds_user salt
  def salted_sha_encrypt(password)
    self.class.local_encrypt(password, salt)
  end

  # Encrypts just using MD5 hash
  def md5_encrypt(password)
    self.class.remote_encrypt(password)
  end

    # Encrypts just using MD5 hash
  def self.remote_encrypt(password)
    MD5.hexdigest(password)
  end


  def remember_token?
    remember_token_expires_at && Time.now.utc < remember_token_expires_at 
  end

  # These create and unset the fields required for remembering sds_users between browser closes
  def remember_me
    self.remember_token_expires_at = 2.weeks.from_now.utc
    self.remember_token            = salted_sha_encrypt("#{email}--#{remember_token_expires_at}")
    save(false)
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    save(false)
  end

  protected
    # before filter 
    def encrypt_password
      return if password.blank?
      self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{login}--") if new_record?
      self.crypted_password = local_encrypt(password)
      self.password_hash = MD5.hexdigest(password)
    end
    
    def password_required?
      crypted_password.blank? || !password.blank?
    end
end