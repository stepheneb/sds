class OfferingsAttribute < ActiveRecord::Base

  
  validates_presence_of :name
  
  belongs_to :offering
  
  def before_validation
    attributes.each do | attribute, val|
      if !val.nil? && val.respond_to?(:strip)
        s = val.strip
        send("#{attribute}=", s.size == 0 ? nil : s)
      end
    end
  end

end