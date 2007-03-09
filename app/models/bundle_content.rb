class BundleContent < ActiveRecord::Base
  set_table_name "sds_bundle_contents"
  has_one :bundle
end
