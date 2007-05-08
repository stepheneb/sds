class ModelActivityDataset < ActiveRecord::Base
  set_table_name "sds_pas_model_activity_datasets"
  belongs_to :sock
  has_many :model_activity_modelrun
  has_many :computational_input
  has_many :representational_type
  
  validates_presence_of :sock
  
    after_save :process_content
    before_save :process_attributes
    
    def process_attributes
      xml = REXML::Document.new(self.sock.value)
      self.name = xml.elements['/modelactivitydata/name'].get_text.to_s
      begin
        self.start_time = Float(xml.elements['/modelactivitydata/start_time'].get_text.to_s)
      rescue
        self.start_time = nil
      end
      begin
        self.end_time = Float(xml.elements['/modelactivitydata/end_time'].get_text.to_s)
      rescue
        self.end_time = nil
      end
    end
    
    def process_content
      # begin
        xml = REXML::Document.new(self.sock.value)
        create_model_activity_dataset(xml)
      # rescue => e
      #  puts "Bad Model Activity Data in sock #{self.sock.id}: #{e}"
      #  self.destroy
      # end
    end
    
    def create_model_activity_dataset(xml)

      xml.elements.each('/modelactivitydata/computational_input') do |ci_xml|
        find_computational_input_xml(ci_xml)
      end

      xml.elements.each('/modelactivitydata/representational_attribute') do |rt_xml|
        rt = find_representational_type_xml(rt_xml)
        rt_xml.elements.each('value_list/value') do |ra_xml|
          find_representational_attribute_xml(ra_xml, rt)
        end
      end

      # model: model_activity_modelrun
      xml.elements.each("//modelrun") do |mr_xml|
      begin
        st = Float(mr_xml.elements['start_time'].get_text.to_s)
      rescue
        st = nil
      end
      begin
        et = Float(mr_xml.elements['end_time'].get_text.to_s)
      rescue
        et = nil
      end
        mr = self.model_activity_modelrun.create(
                   :start_time => st,
                   :end_time => et
        )
        
        # model: computational_input_value
        mr_xml.elements.each('computational_input_value') do |civ_xml|
          ci_ref = civ_xml.attributes['reference'].to_s
          begin
            time = Float(civ_xml.elements['time'].get_text.to_s)
          rescue
            time = nil
          end
          ci = self.computational_input.find(:first, :conditions => ["name = ?", ci_ref])
          civ = ci.computational_input_value.create(:value => civ_xml.elements['value'].get_text.to_s, :time => time)
          mr.computational_input_value.push(civ)
        end
        
        # model: computational_input_value
        # This is where the civ's have been aggregated into one entry
        mr_xml.elements.each('computational_input_values') do |civs_xml|
          ci_ref = civs_xml.attributes['reference'].to_s
          ci = self.computational_input.find(:first, :conditions => ["name = ?", ci_ref])
          
          val = civs_xml.attributes['start'].to_s
          val << "|" << civs_xml.attributes['end'].to_s
          val << "|" << civs_xml.attributes['min'].to_s
          val << "|" << civs_xml.attributes['max'].to_s
          val << "|" << civs_xml.attributes['avg'].to_s
          val << "|" << civs_xml.attributes['num'].to_s
          civ = ci.computational_input_value.create(:value => val, :time => nil)
          mr.computational_input_value.push(civ)
        end
        
        # model: representational_value
        mr_xml.elements.each('representational_attribute_value') do |rv_xml|
          ra_ref = rv_xml.attributes['reference'].to_s
          ra_val = rv_xml.elements['value'].get_text.to_s
          begin
            time = Float(rv_xml.elements['time'].get_text.to_s)
          rescue
            time = nil
          end
          ra = self.representational_type.find(:first, :conditions => ["name = ?", ra_ref])
          rt = ra.representational_attribute.find(:first, :conditions => ["value = ?", ra_val])
          rv = rt.representational_value.create(:time => time)
          mr.representational_value.push(rv)
        end
      end
    end
    
    def find_computational_input_xml(ci_xml)
      name = ci_xml.attributes["name"]
      units = ci_xml.elements['units'].get_text.to_s
      range_max = ci_xml.elements['range/max_value'].get_text.to_s
      range_min = ci_xml.elements['range/min_value'].get_text.to_s
      ci = self.computational_input.find(:first, :conditions => ["name = :name and units = :units and range_max = :range_max and range_min = :range_min",
            {:name => name, :units => units, :range_max => range_max, :range_min => range_min}])
      if ci
        self.computational_input.push(ci)
      else
        self.computational_input.create(:name => name, :units => units, :range_max => range_max, :range_min => range_min)
      end
    end
    
    def find_representational_type_xml(rt_xml)
      name = rt_xml.attributes["name"].to_s
      rt = self.representational_type.find(:first, :conditions => ["name = :name", {:name => name}])
      if rt
        self.representational_type.push(rt)
      else
        rt = self.representational_type.create(:name => name)
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
  end
