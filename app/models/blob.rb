class Blob < ActiveRecord::Base
  has_and_belongs_to_many :bundles
  
  before_create :create_token
  
  def create_token
    # create a random string which will be used to verify permission to view this blob
    self.token = UUID.timestamp_create().hexdigest
  end
end
