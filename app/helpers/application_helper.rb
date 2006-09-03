# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  def display_xml(obj)
    "<p><b>XML output representation: </b></p>" +
    "<p><code>#{h(obj.to_xml)}</code></p>"
  end
  
end
