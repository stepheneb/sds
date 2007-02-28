# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  def display_xml(obj, options=nil)
    except = ['created_at', 'updated_at'] 
    if (options.is_a? Array) && !options.blank?
      except << options
    end
    "<p><b>XML output representation: </b></p>" +
#    "<p><code>#{h(obj.to_xml(:except => ['created_at', 'updated_at']))}</code></p>"
    "<p><code>#{h(obj.to_xml(:except => except))}</code></p>"
  end

  # This method will work the same as image_path
  # image_path("image.gif") => /images/image.gif
  # however if there is an optional parameter hash like this:
  # image_path("image.gif", :only_path => false) => http://rails.host.com/images/image.gif
  def image_url(path, options=nil)
    p = image_path(path)
    if options
      my_rewrite_url(p, options)
    else
      p
    end
  end

  # my_rewrite_url grabbed from ActionController::UrlRewriter, file: url_rewriter.rb 
  def my_rewrite_url(path, options)
    rewritten_url = ""
    unless options[:only_path]
      rewritten_url << (options[:protocol] || @request.protocol)
      rewritten_url << (options[:host] || @request.host_with_port)
    end
#    rewritten_url << @request.relative_url_root.to_s unless options[:skip_relative_url_root]
    rewritten_url << path
    rewritten_url << '/' if options[:trailing_slash]
    rewritten_url << "##{options[:anchor]}" if options[:anchor]
    rewritten_url
  end
  
end
