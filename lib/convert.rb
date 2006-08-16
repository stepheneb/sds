module Convert
  def Convert.hash_from_xml(xml_string)
    Convert.undasherize_keys(XmlSimple.xml_in(xml_string, 'forcearray'   => false))
  end

  def Convert.undasherize_keys(params)
    case params.class.to_s
      when "Hash"
        params.inject({}) do |h,(k,v)|
          h[k.to_s.tr("-", "_")] = Convert.undasherize_keys(v)
          h
        end
      when "Array"
        params.map { |v| Convert.undasherize_keys(v) }
      else
        params
    end
  end
  
end
