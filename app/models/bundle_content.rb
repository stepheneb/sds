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
        workgroup_user_names = self.bundle.workgroup.workgroup_memberships.collect {|m| m.sail_user.name}.join(', ')
        ot [/anon_single_user/] = workgroup_user_names
        ot
      end
    else
      nil
    end
  end
end
