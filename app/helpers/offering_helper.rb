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
  
  def render_jnlp_body(xml, jnlp, resources)
    #  xml << info.to_s
    xml.information {
      xml.title(@portal.title)
      xml.vendor(@portal.vendor)
      xml.homepage("href" => @portal.home_page_url)
      xml.description(@portal.description)
      xml.icon("href" => @portal.image_url, "height" => "64", "width" => "64")
  #    xml << nl + "<offline-allowed/>" 
    }
    if USE_LIBXML
      xml << jnlp.find('./security').first.to_s
    else
      xml << jnlp.elements["security"].to_s
    end

    resources.each do |r| 
      xml << "\n" + r.to_s
    end

    if USE_LIBXML
      xml << "\n#{jnlp.find('./application-desc').first}"
    else
      # work-around rexml escaping of the &
      output = jnlp.elements["application-desc"].to_s.gsub(/&amp;/, '&')
      xml << "\n#{output}"
    end
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
