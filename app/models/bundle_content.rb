class BundleContent < ActiveRecord::Base
  set_table_name "sds_bundle_contents"
  belongs_to :bundle
end
