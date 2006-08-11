class PortalUrl < ActiveRecord::Base
  set_table_name "sds_portal_urls"
  belongs_to :portal
end
