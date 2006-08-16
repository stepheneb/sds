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
end
