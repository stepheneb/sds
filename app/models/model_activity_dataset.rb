class ModelActivityDataset < ActiveRecord::Base

  belongs_to :sock
  has_many :model_activity_modelrun, :dependent => :destroy
  has_many :computational_input, :dependent => :destroy
  has_many :representational_type, :dependent => :destroy
  has_many :pas_findings, :dependent => :destroy
  
  validates_presence_of :sock
  # validates_presence_of :content
  
  before_create :my_setup
  before_create :process_attributes
  after_create :process_content
  
  def my_setup
    @attrs = { :name => "name", :start_time => "start_time", :units => "units",
      :end_time => "end_time", :value => "value", :start => "start",
      :text => "text", :evidence => "evidence", :sequence => "sequence",
      :goal => "goal", :number => "number", :time => "time", :end => "end",
      :min => "min", :max => "max", :avg => "avg", :num => "num", :reference => "reference",
      :min_value => "min_value", :max_value => "max_value", :uuid => "id"
    }
    @elements = { :modelactivitydata => "modelactivitydata", :findings => "findings",
      :finding => "finding", :computational_input => "computational_input",
      :representational_attribute => "representational_attribute", :modelruns => "modelruns",
      :modelrun => "modelrun", :computational_input_value => "computational_input_value",
      :computational_input_values => "computational_input_values", :trial => "trial",
      :range => "range", :representational_attribute_value_list => "value_list/value",
      :representational_attribute_value => "representational_attribute_value",
    }

    if self.sock.pod.pas_type == "ot_learner_data"
      @attrs.merge!({ :start_time => "startTime", :end_time => "endTime",
        :min_value => "minValue", :max_value => "maxValue",
      })
      
      # FIXME Not sure if "valueList/OTValue" is correct for the representational_attribute_value_list...
      @elements.merge!({ :modelactivitydata => "OTModelActivityData", :modelruns => "modelRuns",
        :finding => "OTFinding", :computational_input => "computationalInputs/OTComputationalInput",
        :representational_attribute => "representationalAttributeValues/OTRepresentationalAttribute",
        :modelrun => "OTModelRun", :computational_input_value => "computationalInputValues/OTComputationalInputValue",
        :computational_input_values => "computationalInputValues/OTComputationalInputValues",
        :range => "range/OTRange", :representational_attribute_value_list => "valueList/OTValue",
      })
    end
    return true
  end
  
  def process_attributes
    xml = REXML::Document.new(self.content)
    self.name = get_attribute_or_element_value(xml.elements["//#{@elements[:modelactivitydata]}"],@attrs[:name])
    self.start_time = get_attribute_or_element_value(xml.elements["//#{@elements[:modelactivitydata]}"],@attrs[:start_time]) {|v| Float(v) }
    self.end_time = get_attribute_or_element_value(xml.elements["//#{@elements[:modelactivitydata]}"],@attrs[:end_time]) {|v| Float(v) }
    return true
  end
  
  def process_content
    # begin
    xml = REXML::Document.new(self.content)
    create_model_activity_dataset(xml)
    # rescue => e
    #  puts "Bad Model Activity Data in sock #{self.sock.id}: #{e}"
    #  self.destroy
    # end
    return true
  end
  
  # looks for a child element or attribute 'attr' within 'xml'.
  # if default is specified, uses that as a default value in case the attribute doesn't exist
  # or there is an error in processing. An optional block can be passed to do some post-processing
  # which if it fails with an exception, will cause this method to return the default
  # by default it returns a String or nil
  def get_attribute_or_element_value(xml, attr, default = nil, &f)
    val = default
    begin
      snip = xml.elements[attr]
      if snip.elements.size > 0
        if snip.elements.size == 1 && snip.elements['object']
          # must be an otml reference to a different OTObject
          # return the refid
          val = snip.elements['object'].attributes['refid'].to_s
        else
          # otherwise just return the whole snippet
          val = snip.to_s
        end
      else
        val = snip.get_text.to_s
      end
    rescue
      begin
        val = xml.attributes[attr].to_s
      rescue
        # logger.warn("Couldn't find attribute or element: #{attr}")
      end
    end
    begin
      if f
        val = yield(val)
      end
    rescue
      val = default
    end
    return val
  end
  
  def create_model_activity_dataset(xml)
    xml.elements.each("//#{@elements[:modelactivitydata]}/#{@elements[:findings]}") do |finding_xml|
      finding_xml.elements.each("#{@elements[:finding]}") do |finding|
        text = get_attribute_or_element_value(finding, @attrs[:text])
        evidence = get_attribute_or_element_value(finding, @attrs[:evidence])
        sequence = get_attribute_or_element_value(finding, @attrs[:sequence])
        
        PasFinding.create(:model_activity_dataset_id => self.id, :evidence => evidence, :text => text, :sequence => sequence)
      end
    end
    
    xml.elements.each("//#{@elements[:modelactivitydata]}/#{@elements[:computational_input]}") do |ci_xml|
      find_computational_input_xml(ci_xml)
    end
    
    xml.elements.each("//#{@elements[:modelactivitydata]}/#{@elements[:representational_attribute]}") do |rt_xml|
      rt = find_representational_type_xml(rt_xml)
      rt_xml.elements.each(@elements[:representational_attribute_value_list]) do |ra_xml|
        find_representational_attribute_xml(ra_xml, rt)
      end
    end
    
    # model: model_activity_modelrun
    xml.elements.each("//#{@elements[:modelactivitydata]}/#{@elements[:modelruns]}/#{@elements[:modelrun]}") do |mr_xml|
      st = get_attribute_or_element_value(mr_xml, @attrs[:start_time], nil) {|v| Float(v) }
      et = get_attribute_or_element_value(mr_xml, @attrs[:end_time], nil) {|v| Float(v) }
      tg = get_attribute_or_element_value(mr_xml.elements[@elements[:trial]], @attrs[:goal], nil)
      tn = get_attribute_or_element_value(mr_xml.elements[@elements[:trial]], @attrs[:number], nil)
      
      mr = self.model_activity_modelrun.create(
                                               :start_time => st,
                                               :end_time => et,
                                               :trial_goal => tg,
                                               :trial_number => tn
      )
      
      # model: computational_input_value
      mr_xml.elements.each(@elements[:computational_input_value]) do |civ_xml|
        ci_ref = get_attribute_or_element_value(civ_xml, @attrs[:reference], nil)
        time = get_attribute_or_element_value(civ_xml, @attrs[:time], nil)
        query = "name = ?"
        if ci_ref =~ /[0-9a-f]+-[0-9a-f]+-[0-9a-f]+-[0-9a-f]+-[0-9a-f]+/
          query = "uuid = ?"
        end
        ci = self.computational_input.find(:first, :conditions => [query, ci_ref])
        civ = ci.computational_input_value.create(:value => get_attribute_or_element_value(civ_xml, @attrs[:value], nil), :time => time)
        mr.computational_input_value.push(civ)
      end
      
      # model: computational_input_value
      # This is where the civ's have been aggregated into one entry
      mr_xml.elements.each(@elements[:computational_input_values]) do |civs_xml|
        ci_ref = get_attribute_or_element_value(civs_xml, @attrs[:reference], nil)
        query = "name = ?"
        if ci_ref =~ /[0-9a-f]+-[0-9a-f]+-[0-9a-f]+-[0-9a-f]+-[0-9a-f]+/
          query = "uuid = ?"
        end
        ci = self.computational_input.find(:first, :conditions => [query, ci_ref])
        time = get_attribute_or_element_value(civs_xml,@attrs[:time], 0)
        
        val = get_attribute_or_element_value(civs_xml,@attrs[:start])
        val << "|" << get_attribute_or_element_value(civs_xml,@attrs[:end])
        val << "|" << get_attribute_or_element_value(civs_xml,@attrs[:min])
        val << "|" << get_attribute_or_element_value(civs_xml,@attrs[:max])
        val << "|" << get_attribute_or_element_value(civs_xml,@attrs[:avg])
        val << "|" << get_attribute_or_element_value(civs_xml,@attrs[:num])
        civ = ci.computational_input_value.create(:value => val, :time => time)
        mr.computational_input_value.push(civ)
      end
      
      # model: representational_value
      mr_xml.elements.each(@elements[:representational_attribute_value]) do |rv_xml|
        ra_ref = get_attribute_or_element_value(rv_xml, @attrs[:reference], nil)
        ra_val = get_attribute_or_element_value(rv_xml, @attrs[:value], nil)
        time = get_attribute_or_element_value(rv_xml,@attrs[:time]) {|v| Float(v) }
        
        query = "name = ?"
        if ra_ref =~ /[0-9a-f]+-[0-9a-f]+-[0-9a-f]+-[0-9a-f]+-[0-9a-f]+/
          query = "uuid = ?"
        end
        ra = self.representational_type.find(:first, :conditions => [query, ra_ref])
        rt = ra.representational_attribute.find(:first, :conditions => ["value = ?", ra_val])
        rv = rt.representational_value.create(:time => time)
        mr.representational_value.push(rv)
      end
    end
  end
  
  def find_computational_input_xml(ci_xml)
    name = get_attribute_or_element_value(ci_xml,@attrs[:name],nil)
    uuid = get_attribute_or_element_value(ci_xml,@attrs[:uuid],nil)
    units = get_attribute_or_element_value(ci_xml,@attrs[:units],nil)
    range_max = get_attribute_or_element_value(ci_xml.elements[@elements[:range]],@attrs[:max_value], nil)
    range_min = get_attribute_or_element_value(ci_xml.elements[@elements[:range]],@attrs[:min_value], nil)
    ci = self.computational_input.find(:first, :conditions => ["name = :name and units = :units and range_max = :range_max and range_min = :range_min and uuid = :uuid",
    {:name => name, :units => units, :range_max => range_max, :range_min => range_min, :uuid => uuid}])
    if ci
      self.computational_input.push(ci)
    else
      self.computational_input.create(:name => name, :units => units, :range_max => range_max, :range_min => range_min, :uuid => uuid)
    end
  end
  
  def find_representational_type_xml(rt_xml)
    name = get_attribute_or_element_value(rt_xml,@attrs[:name],nil)
    uuid = get_attribute_or_element_value(rt_xml,@attrs[:uuid],nil)
    rt = self.representational_type.find(:first, :conditions => ["name = :name AND uuid = :uuid", {:name => name, :uuid => uuid}])
    if rt
      self.representational_type.push(rt)
    else
      rt = self.representational_type.create(:name => name, :uuid => uuid)
    end
    rt
  end
  
  def find_representational_attribute_xml(ra_xml, rt)
    value = ra_xml.text.to_s
    ra = rt.representational_attribute.find(:first, :conditions => ["value = :value", {:value => value}])
    if ra
      rt.representational_attribute.push(ra)
    else
      rt.representational_attribute.create(:value => value)
    end
  end
  
  def fix_incorrect_airbag_mad()
    sock = self.sock
    if self.name != "Airbag"
      # we only need to check Airbag models
      return
    end
    raw_data_socks = sock.bundle.socks.collect {|s|
      if s.pod.pas_type == "trial_data"
        s
      end
    }
    arr = []
    raw_data_socks = raw_data_socks.compact
    ident = "p: #{self.sock.bundle.workgroup.offering.portal_id}, o: #{self.sock.bundle.workgroup.offering_id}, w: #{self.sock.bundle.workgroup_id}, mad: #{self.id}"
    if raw_data_socks.length < 1
      logger.error("MAD Dataset (#{ident}): Couldn't find a raw data sock entry.")
      raise "MAD Dataset (#{ident}): Couldn't find a raw data sock entry."
    else
      ## Combine all of available raw datasets
      # logger.error("MAD Dataset (#{ident}): Found more than 1 raw data sock entry.")
      # raise "MAD Dataset (#{ident}): Found more than 1 raw data sock entry."
      raw_data_socks.each do |rds|
        raw_data = rds.unpack_gzip_b64_value
        arr += raw_data.scan(/^[f|t]?.*Trial ([0-9]+) Dummy,([0-9\.\-]+),([0-9\.\-]+),([0-9\.\-]+),.*/).uniq
      end
    end
    
    # parse the raw data into a useable format
    # format is "visible, Trial NNN Dummy,x,v,t,safe,rgb"
    # x = "Dummy Position"
    # v = "Dummy Velocity"
    # t = "Dummy Time"
    hash = {}
    arr.each do |v|
      if hash.has_key? v[0]
        if hash[v[0]]["Dummy Position"] != v[1]
          logger.warn("MAD Dataset (#{ident}): Data for Trial #{v[0]} already exists in the hash!")
          logger.warn("Position is different: o: #{hash[v[0]]["Dummy Position"]}, n: #{v[1]}")
        elsif hash[v[0]]["Dummy Velocity"] != v[2]
          logger.warn("MAD Dataset (#{ident}): Data for Trial #{v[0]} already exists in the hash!")
          logger.warn("Velocity is different: o: #{hash[v[0]]["Dummy Velocity"]}, n: #{v[2]}")
        elsif hash[v[0]]["Dummy Time"] != v[3]
          logger.warn("MAD Dataset (#{ident}): Data for Trial #{v[0]} already exists in the hash!")
          logger.warn("Time is different: o: #{hash[v[0]]["Dummy Time"]}, n: #{v[3]}")
        else
          # logger.warn("Couldn't find a difference!")
        end
      end
      hash[v[0]] = { "Dummy Position" => v[1], "Dummy Velocity" => v[2], "Dummy Time" => v[3]}
    end
    # compare the raw data with the existing mad data
    # update the mad data if necessary
    self.model_activity_modelrun.each do |mr|
      # logger.info("Run: #{mr}, trial: #{mr.trial_number}")
      raw_run_data = hash["#{mr.trial_number}"]
      if raw_run_data == nil
        logger.warn("MAD Dataset (#{ident}): No Raw Run data for trial: #{mr.trial_number}")
      else
        # logger.info("raw run: #{raw_run_data}")
        mr.computational_input_value.each do |civ|
          if civ.value != raw_run_data[civ.computational_input.name]
            # logger.info("#{sock.bundle.workgroup.offering_id}.#{sock.bundle.workgroup_id}.#{sock.bundle_id} -- Updated #{civ.computational_input.name} from #{civ.value} to #{raw_run_data[civ.computational_input.name]}")
            civ.value = raw_run_data[civ.computational_input.name]
            civ.save
          else
            # logger.info("#{sock.bundle.workgroup.offering_id}.#{sock.bundle.workgroup_id}.#{sock.bundle_id} -- No Update Necessary")
          end
        end
      end
    end
  end
end
