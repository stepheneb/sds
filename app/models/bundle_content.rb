# == Schema Information
# Schema version: 58
#
# Table name: sds_bundle_contents
#
#  id      :integer(11)   not null, primary key
#  content :text          
#

class BundleContent < ActiveRecord::Base
  set_table_name "sds_bundle_contents"
  has_one :bundle
  
  def ot_learner_data    
    sock = self.bundle.socks.detect{|i| i.pod.rim_name == 'ot.learner.data'}
    if sock
      ot = sock.text
      if ot =~ /anon_single_user/
        ot [/anon_single_user/] = self.bundle.workgroup.member_names
        ot
      end
    else
      self.bundle.workgroup.blank_ot_learner_data
    end
  end
end
