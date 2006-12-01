module OfferingHelper
  def add_user_to_config(xml, user)
    xml.void("method" => "add") {
      xml.object("class" => "net.sf.sail.core.entity.User") {
        xml.object("class" => "net.sf.sail.core.uuid.UserUuid") {
          xml.string(user.uuid)
        }
        xml.string(user.name)
      }
    }
  end

  def hash_to_url_params(hash)
    url_params = Array.new    
    hash.each do |k,v|
       if k.kind_of? String and v.kind_of? String
         url_params << k+'='+url_encode(v)
       end
    end
#    ""     
    url_params.join('&')
  end

end
