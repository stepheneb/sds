module ConvertXml
  def ConvertXml.xml_to_hash(xml_string)
    ConvertXml.undasherize_keys(XmlSimple.xml_in(xml_string, 'forcearray'   => false))
  end

  def ConvertXml.undasherize_keys(params)
    case params.class.to_s
      when "Hash"
        params.inject({}) do |h,(k,v)|
          h[k.to_s.tr("-", "_")] = ConvertXml.undasherize_keys(v)
          h
        end
      when "Array"
        params.map { |v| ConvertXml.undasherize_keys(v) }
      else
        params
    end
  end
  
end
